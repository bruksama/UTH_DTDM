# NGỮ CẢNH DỰ ÁN: Trợ lý AI tự chủ triển khai ứng dụng

## 1. TỔNG QUAN ĐỀ TÀI
- **Tên đề tài**: Trợ lý AI cho kỹ sư DevOps: Tự động hóa CI/CD
- **Mục tiêu**: Xây dựng hệ thống CI/CD gọn nhẹ với OpenClaw, ưu tiên ChatOps do con người khởi phát
- **Kiến trúc tổng thể**: Developer push code → GitHub Actions build/push image → Human ra lệnh trên Slack → OpenClaw trên GCP C2 pull image và triển khai

## 2. STACK CÔNG NGHỆ
### CI Layer (Cloud)
- GitHub Actions: Build Docker image, push image lên registry
- Mọi kích hoạt đi qua Slack ChatOps, chỉ handoff metadata cho bước triển khai

### AI/CD Layer (VM - GCP C2)
- **OpenClaw**: AI Agent tự chủ (Node.js/Python)
- **Docker**: Container runtime (không dùng Kubernetes)
- **Docker Compose**: Blue-green deployment pattern
- **SQLite**: Lưu trạng thái deployment

### ChatOps Layer
- Slack native plugin `channels.slack`
- Tương tác trực tiếp trong Slack: `@OpenClaw deploy latest`, `@OpenClaw status`, `@OpenClaw rollback`
- Xác nhận triển khai nếu cần qua phản hồi hội thoại

## 3. KIẾN TRÚC LUỒNG DỮ LIỆU
1. Developer push code → GitHub
2. GitHub Actions build image → Push registry
3. Người vận hành ra lệnh trên Slack: `@OpenClaw deploy latest`
4. OpenClaw đọc metadata image, quyết định có cần xác nhận hay không
5. OpenClaw thực thi: docker pull → docker run → health check
6. Nếu lỗi: rollback + phân tích log bằng AI (Claude API)
7. Thông báo kết quả → Slack

## 4. STATE MACHINE CỦA OPENCLAW
- **IDLE**: Chờ lệnh Slack
- **WAITING_CONFIRMATION**: Chờ người dùng xác nhận
- **DEPLOYING**: Pull image, chạy container mới
- **HEALTH_CHECKING**: Kiểm tra /health endpoint (3 lần, timeout 10s)
- **ACTIVE**: Deploy thành công, traffic chuyển sang
- **ROLLING_BACK**: Health check fail → stop new → start old

## 5. RÀNG BUỘC KỸ THUẬT
- Không dùng Kubernetes (quá phức tạp cho sinh viên)
- Single VM trên GCP C2 (Ubuntu 22.04 LTS)
- Docker Compose cho blue-green (2 container: blue + green)
- Self-hosted: OpenClaw chạy trực tiếp trên VM (không cloud AI)
- Bảo mật: Docker non-root, firewall rule tối thiểu, secrets tách biệt trên GitHub/VM

## 6. PHÂN CÔNG NHÓM
- **Lộc**: OpenClaw Expert - Viết skills, tích hợp Claude API, State machine
- **Duy**: Infrastructure - VM, Docker, Network, Security, Diagram
- **Khang**: CI/CD - GitHub Actions, registry metadata, State API (SQLite)
- **Quyến**: ChatOps - Slack plugin `channels.slack`, Documentation, Testing, Tổng hợp

## 7. STYLE GUIDE CHUNG CHO BÁO CÁO
- Giọng văn: Học thuật, kỹ thuật, khách quan
- Ngôn ngữ: Tiếng Việt (chuyên ngành: giữ nguyên thuật ngữ tiếng Anh như Webhook, Container, v.v.)
- Cấu trúc: Mỗi chương có mở đầu, thân bài (có bullet points/bảng), kết luận ngắn
- Trích dẫn: IEEE format cho tài liệu tham khảo
- Hình ảnh: Diagram phải có caption, đánh số (Hình 3.1, v.v.)

## 8. CÁC TÀI LIỆU THAM KHẢO CHÍNH
- OpenClaw Documentation: docs.openclaw.io
- GitHub Actions Docs: docs.github.com/actions
- Docker Docs: docs.docker.com
- Slack API Docs: api.slack.com
- GCP Compute Engine Docs: cloud.google.com/compute/docs
