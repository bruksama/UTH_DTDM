---
name: deploy-orchestrator
description: Orchestrate Slack-triggered deployment on a single VM: parse deploy commands, resolve target image, run Docker or Compose deployment, perform health checks, switch traffic, rollback on failure, persist deployment state, and return operator-facing results.
metadata:
  openclaw:
    os: ["linux"]
    requires:
      bins: ["docker"]
      config: ["channels.slack"]
---

# Deploy Orchestrator

## Purpose

`deploy-orchestrator` là skill trung tâm cho v1.
Nó chịu trách nhiệm điều phối toàn bộ flow triển khai từ Slack đến Docker/Compose trên single VM.

Skill này tồn tại để giữ deploy flow:
- human-triggered
- deterministic
- dễ demo
- dễ giải thích trong báo cáo

## Scope

Skill này xử lý end-to-end các việc sau:
- nhận lệnh từ Slack
- parse ý định deploy
- resolve image cần triển khai
- đọc trạng thái hiện tại
- quyết định có cần confirmation hay không
- pull image
- chọn candidate color
- start candidate
- chạy health check
- switch traffic nếu pass
- rollback nếu fail
- ghi state/history
- trả kết quả ngắn gọn lại Slack

## Must Not Do

- Không được coi việc image mới xuất hiện trong registry là trigger deploy tự động
- Không được bỏ qua source of truth hiện tại trước khi đổi production state
- Không được trả về kết luận thành công nếu chưa có health result rõ ràng
- Không được dựa vào “trí nhớ hội thoại” thay cho state persistence
- Không được phân tích log quá sâu bên trong skill này nếu đã có `log-analyzer`; chỉ thu thập evidence tối thiểu và gọi skill kia khi cần

## Expected Triggers

Các intent điển hình từ Slack:
- `@OpenClaw deploy latest`
- `@OpenClaw deploy <tag>`
- `@OpenClaw deploy <image>:<tag>`
- `@OpenClaw status`
- `@OpenClaw rollback` (nếu v1 hỗ trợ rollback thủ công)

Nếu intent không rõ:
- hỏi lại ngắn gọn
- không suy diễn mạnh tay

## Inputs

### Required inputs
- Slack message đã được parse thành action
- repository/image reference hoặc alias như `latest`
- current deployment state

### Optional inputs
- approval policy
- environment name
- registry metadata
- previous successful deployment record
- health policy config
- traffic switch config

## Source of Truth

Skill spec này phải chỉ rõ nơi đọc và ghi dữ liệu thật:
- **Current active deployment**: SQLite
- **Previous successful deployment**: SQLite deployment history
- **Requested image**: Slack command
- **Resolved image tag/digest**: registry metadata hoặc CI-produced metadata
- **Health policy**: config file hoặc hardcoded policy versioned trong repo
- **Traffic switch state**: Nginx config / symlink / Compose routing rule / active color field trong SQLite

Nếu các source này chưa được hiện thực, skill phải ghi rõ assumption thay vì giả vờ đã có.

## Command Grammar

### Deploy
Hỗ trợ tối thiểu:
- `deploy latest`
- `deploy <tag>`

Rule đã chốt cho v1:
- `deploy latest` -> resolve tag mới nhất từ registry/API
- `deploy <tag>` -> dùng tag do người vận hành chỉ định

### Status
Hỗ trợ tối thiểu:
- `status`

### Rollback
Tùy chọn cho v1:
- `rollback`

Nếu command vượt ngoài grammar này:
- trả lỗi ngắn gọn
- đưa ví dụ hợp lệ

## Decision Policy

Cho deploy chạy ngay khi:
- command hợp lệ
- resolve được target image
- không có deploy khác đang chạy
- state hiện tại đọc được

Yêu cầu confirmation khi:
- image không rõ provenance
- hệ thống đang ở trạng thái bất thường
- state hiện tại đọc được nhưng có dấu hiệu không nhất quán

Reject khi:
- không resolve được image
- state đang corrupt hoặc thiếu source of truth tối thiểu
- host chưa sẵn sàng để deploy

Ghi chú cho v1:
- không bắt buộc confirmation riêng cho `latest`
- vẫn có thể thêm policy confirm sau nếu cần

## Execution Steps

Thứ tự xử lý chuẩn:

1. Parse command từ Slack
2. Resolve target image
3. Read current state
4. Determine active color và candidate color
5. Optional confirmation nếu policy yêu cầu
6. Pull target image
7. Start candidate bằng Docker hoặc Compose
8. Run health check loop trên route public cho demo
9. Nếu pass: switch traffic sang candidate
10. Persist new active state và history
11. Trả kết quả thành công về Slack
12. Nếu fail ở bước health/switch: rollback tự động
13. Persist failure + rollback result
14. Nếu cần: gọi `log-analyzer`
15. Trả kết quả thất bại/escalation về Slack

## Blue-Green Selection Rules

Phải có rule rõ ràng:
- nếu `active = blue` thì `candidate = green`
- nếu `active = green` thì `candidate = blue`
- nếu chưa có active state, coi đây là **bootstrap deploy** và deploy vào `blue`

Không được chọn candidate dựa trên suy đoán mơ hồ.

## Health Policy

Tối thiểu cần chốt cho v1 demo:
- route kiểm tra: `/`
- số lần thử: `3`
- timeout mỗi lần: `10s`
- khoảng nghỉ giữa các lần thử: implementation-defined, ví dụ `2s`
- pass condition:
  - route `/` phản hồi thành công
  - không yêu cầu endpoint `/health` riêng trong bản demo hiện tại

Lý do chọn rule này:
- repo demo hiện tại là web app đơn giản, phù hợp với smoke check qua route public
- có thể nâng cấp lên `/health` ở phiên bản sau

Skill phải mô tả rõ evidence được giữ lại:
- HTTP status nếu có
- URL đã kiểm tra
- timestamp
- container/container-color được kiểm tra

## Traffic Switch Rules

Cho v1, “switch traffic” được chốt là:
- đổi upstream active trong cấu hình Nginx giữa `app-blue` và `app-green`
- sau đó reload hoặc restart Nginx để áp dụng cấu hình mới

Không được dùng cụm “switch traffic” nếu chưa nêu mechanism cụ thể.

## Rollback Rules

Rollback được kích hoạt khi:
- health check fail
- traffic switch fail
- candidate container crash ngay sau startup

Cho v1:
- rollback là **tự động** khi deploy thất bại
- không yêu cầu hỗ trợ lệnh rollback thủ công từ Slack trong command set v1

Rollback phải trả lời rõ:
- rollback về image/tag nào
- rollback về color nào
- source of truth nào được dùng để xác định previous live version
- nếu rollback cũng fail thì escalation thế nào

## State Reads/Writes

Skill này phải ghi rõ các field tối thiểu cần có trong SQLite:
- deployment_id
- requested_by
- requested_command
- requested_image
- resolved_image_tag
- resolved_image_digest
- previous_active_color
- candidate_color
- final_active_color
- status
- rollback_occurred
- started_at
- finished_at
- error_summary

Nếu chưa chốt schema đầy đủ, vẫn phải chốt danh sách field tối thiểu cho báo cáo.

## Outputs

Skill nên trả ra object hoặc logical result có các trường sau:
- `action`
- `requested_image`
- `resolved_image`
- `previous_active_color`
- `candidate_color`
- `health_result`
- `final_state`
- `rollback_occurred`
- `operator_summary`
- `escalation_reason`

### Expected logical outcomes
- `deploy_succeeded`
- `needs_confirmation`
- `deploy_rejected`
- `deploy_failed_rollback_succeeded`
- `deploy_failed_rollback_failed`
- `status_report`

Ghi chú cho v1:
- chưa cần logical outcome riêng cho rollback thủ công từ Slack

## Slack Response Rules

Phản hồi phải:
- ngắn
- rõ outcome
- có image/tag cụ thể
- có active color trước/sau nếu deploy xảy ra
- nói rõ rollback có diễn ra hay không

Ví dụ kiểu output tốt:
- `Deploy thành công: app:1.4.2 đã lên green, health check pass, traffic đã chuyển.`
- `Deploy thất bại: app:1.4.2 fail health check, đã rollback về blue.`
- `Không thể deploy latest vì chưa resolve được image digest.`

## Failure and Escalation

Escalate khi:
- không đọc được state
- không xác định được previous stable deployment
- rollback fail
- traffic switch ở trạng thái không chắc chắn

Khi escalation:
- không tuyên bố hệ thống an toàn nếu chưa chắc
- nêu ngắn gọn điều chưa chắc
- cung cấp context để `log-analyzer` hoặc operator xử lý tiếp

## Implementation Boundary

Đối với v1, nên để các thao tác deterministic nằm ở script hoặc implementation layer:
- pull image
- start candidate
- health check loop
- switch traffic
- rollback
- persist state/history

Skill này nên đóng vai trò:
- mô tả contract
- mô tả workflow
- mô tả decision points
- không thay thế implementation script thực tế

## Why this design fits the project

Thiết kế này phù hợp với đề tài vì:
- không cần Kubernetes
- giữ con người là điểm khởi phát deploy
- đủ thể hiện AI Agent trong quy trình triển khai
- vẫn đơn giản cho phạm vi báo cáo sinh viên
- khớp với repo demo hiện tại đang dùng Docker Compose + Nginx blue-green
