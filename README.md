# UTH_DTDM — Hệ thống CI/CD gọn nhẹ với OpenClaw + ChatOps (tài liệu học thuật)

Kho tài liệu phục vụ báo cáo học thuật về trợ lý AI DevOps vận hành CI/CD gọn nhẹ trên single VM. Kiến trúc cuối cùng: GitHub Actions chỉ build/push image; con người ra lệnh trên Slack; OpenClaw xử lý ChatOps qua plugin Slack gốc (Socket Mode) và điều phối blue‑green bằng Docker Compose + Nginx; trạng thái lưu bằng SQLite.

## Vấn đề & Mục tiêu
- Vận hành thủ công dễ lỗi, rollback chậm, thiếu lịch sử trạng thái.
- Kubernetes quá nặng cho phạm vi demo sinh viên.
- Mục tiêu: đơn giản hóa pipeline nhưng vẫn có tự động hóa, an toàn triển khai, có khả năng rollback/health‑check và nhật ký minh bạch.

## Kiến trúc cuối cùng (Source of Truth)
- CI/CD: GitHub Actions chỉ build và push Docker image lên registry (không gửi webhook).
- OpenClaw: chạy trên VM GCP C2 (Ubuntu 22.04), kết nối Slack bằng plugin gốc `channels.slack` qua Socket Mode.
- ChatOps: người dùng gõ trên Slack, ví dụ: `@OpenClaw deploy latest`.
- Kỹ năng OpenClaw (Python skills): `deploy_decision`, `container_control`, `health_checker`, `rollback_handler`, `log_analyzer`.
- Triển khai: Docker Compose blue‑green + Nginx switch traffic; SQLite theo dõi state/history.

### Luồng chính end‑to‑end
1. Developer push code lên GitHub.
2. GitHub Actions build image và push vào registry.
3. Người vận hành gõ lệnh trên Slack: `@OpenClaw deploy latest`.
4. OpenClaw nhận tín hiệu qua plugin Slack gốc, quyết định triển khai (có thể hỏi xác nhận).
5. VM pull image, khởi chạy phiên bản mới, chạy health check.
6. Nginx chuyển traffic sang phiên bản mới nếu healthy; nếu fail, rollback và phân tích log.
7. Ghi nhận kết quả vào SQLite và phản hồi lại Slack bằng Markdown.

## Phân công
- Lộc: OpenClaw, logic AI, state machine, rollback.
- Duy: VM, Docker, network, security, diagram.
- Khang: GitHub Actions, registry, SQLite state, cost.
- Quyến: Slack App (Socket Mode), cấu hình plugin `channels.slack`, luồng hội thoại ChatOps, chuẩn tài liệu và tổng hợp báo cáo.

## Phạm vi repository
- Đây là repository cho báo cáo học thuật và tài liệu hướng dẫn.
- Mã demo (workflow, skills, compose, script) sẽ đặt ở repository riêng (TBD).

## Tài liệu cốt lõi
- docs/project-overview-pdr.md — Tổng quan, mục tiêu, kiến trúc, PDR.
- docs/project-tracker.md — Tiến độ, phase, quyết định đã chốt.
- docs/code-standards.md — Quy ước trình bày, code block, diagram, naming.
- docs/prompts/* — Ngữ cảnh gốc theo vai trò (Infrastructure, CI/CD, OpenClaw, ChatOps).

## Ghi chú triển khai demo (định hướng)
- VM: GCP C2, Ubuntu 22.04; Docker CE, Docker Compose v2, Nginx, SQLite.
- Slack: Tạo Slack App trên `api.slack.com`, bật Socket Mode; lấy App Token/Bot Token; cấu hình OpenClaw dùng `channels.slack`.
- Bảo mật: lưu secrets trong GitHub/VM, tường lửa tối thiểu, non‑root containers.

## Trạng thái hiện tại
- Repo chứa tài liệu và prompts khởi tạo; chưa kèm mã demo.
- Các tệp cần đọc trước: `docs/project-overview-pdr.md`, `docs/code-standards.md`, `docs/project-tracker.md`.
