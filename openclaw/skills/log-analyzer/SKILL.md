---
name: log-analyzer
description: Analyze deployment or rollback failures on the single-VM Docker host, inspect logs from containers and related services, summarize likely root causes, and prepare concise operator-facing guidance for Slack.
metadata:
  openclaw:
    os: ["linux"]
    requires:
      bins: ["docker"]
      config: []
---

# Log Analyzer

## Purpose

`log-analyzer` là skill phụ cho v1.
Nó không tham gia điều khiển deploy flow chính, mà chỉ được dùng để đọc evidence kỹ thuật và tóm tắt lỗi theo cách operator có thể hiểu nhanh.

Skill này tồn tại để giữ phần “AI hỗ trợ” ở nơi hợp lý nhất:
- sau deploy fail
- sau rollback fail
- khi cần chẩn đoán nguyên nhân để báo về Slack

## Scope

Skill này làm các việc sau:
- đọc các log source liên quan
- gom evidence ngắn gọn
- phân biệt deploy failure và rollback failure
- đưa ra root-cause hypothesis ngắn gọn, có mức tự tin vừa phải
- đề xuất operator action tiếp theo
- tạo summary phù hợp để gửi lên Slack

## Must Not Do

- Không được tự start/stop container
- Không được tự switch traffic
- Không được tự sửa state/history
- Không được khẳng định nguyên nhân gốc nếu evidence còn yếu
- Không được thay thế hoàn toàn raw logs; summary chỉ là lớp hỗ trợ cho operator

## Typical Trigger Conditions

Gọi skill này khi:
- candidate container fail startup
- health check fail
- traffic switch fail
- rollback fail
- operator yêu cầu giải thích ngắn gọn vì sao deploy thất bại

Policy cho v1:
- không cần gọi skill này cho mọi deploy thành công bình thường
- nên auto-run khi deploy fail hoặc rollback fail

## Inputs

### Required inputs
- deployment context hoặc rollback context
- target image / container / color liên quan
- log sources khả dụng

### Optional inputs
- timeframe cần phân tích
- line limit
- health-check evidence
- Nginx switch result
- previous deployment record

## Log Sources

Tối thiểu nên hỗ trợ các nguồn sau nếu có:
- Docker container logs của candidate
- Docker container logs của active/previous container
- Docker Compose logs
- deploy script logs
- Nginx logs nếu traffic switch liên quan đến reverse proxy
- systemd service status/output nếu deploy daemon hoặc helper script chạy qua service

Skill spec nên chỉ rõ thứ tự ưu tiên đọc log để tránh lan man.

## Analysis Scope

Mặc định nên ưu tiên:
1. candidate container logs
2. health-check result
3. traffic-switch evidence
4. rollback-related logs
5. supporting host/service logs nếu cần

Không nên đọc toàn bộ log vô hạn.
Rule mặc định cho v1 nên là:
- ưu tiên log trong khoảng thời gian của deploy gần nhất
- nếu không có timestamp boundary rõ, lấy khoảng `100` dòng cuối từ log nguồn chính trước

## What to look for

Các nhóm lỗi cần ưu tiên nhận diện:
- image pull thất bại
- container start thất bại
- port binding conflict
- missing env/config/secrets
- app crash loop
- health endpoint fail
- reverse proxy / traffic switch fail
- rollback fail do previous version không còn hợp lệ

Nếu không đủ evidence để chốt một nhóm lỗi cụ thể:
- nói rõ là `chưa đủ evidence`
- không bịa root cause

## Outputs

`log-analyzer` nên trả về tối thiểu:
- `incident_type`
- `suspected_root_cause`
- `confidence`
- `evidence_snippets`
- `affected_container_or_color`
- `recommended_operator_action`
- `slack_summary`

Trong đó `confidence` nên dùng scale đơn giản:
- `high`
- `medium`
- `low`

### Expected logical outcomes
- `deploy_failure_analysis`
- `rollback_failure_analysis`
- `insufficient_evidence`

## Output Format

Summary cho Slack nên:
- ngắn
- technical nhưng dễ hiểu
- nêu lỗi chính trước
- nêu action tiếp theo sau

Ví dụ tốt:
- `Deploy fail trên green: container khởi động nhưng /health trả 500 trong 3 lần thử. Nghi ngờ app thiếu biến môi trường DB_URL.`
- `Rollback fail: không khôi phục được container blue vì image cũ không còn available trên host.`

## Operator Guidance

Action gợi ý nên thực tế và ngắn gọn, ví dụ:
- kiểm tra env file
- kiểm tra image tag/digest
- xem raw logs của container cụ thể
- thử rollback thủ công
- xác minh config Nginx

Không nên đưa khuyến nghị mơ hồ kiểu:
- “xem lại hệ thống tổng thể”
- “kiểm tra toàn bộ pipeline”

## Relationship with deploy-orchestrator

`deploy-orchestrator` là skill chính.
`log-analyzer` chỉ là skill hỗ trợ khi execution path có lỗi hoặc cần chẩn đoán.

Boundary cần giữ rõ:
- `deploy-orchestrator` quyết định và thực thi flow
- `log-analyzer` đọc evidence và tóm tắt nguyên nhân

## Why this design fits the project

Thiết kế này hợp với đề tài vì:
- giữ AI ở phần có giá trị rõ ràng nhất: giải thích lỗi
- không làm execution flow trở nên quá mơ hồ
- dễ trình bày trong báo cáo học thuật
- dễ demo khi có tình huống deploy fail hoặc rollback fail
- khớp với mô hình demo hiện tại dùng Nginx + Docker Compose và smoke check route public
