# NGỮ CẢNH DỰ ÁN: Trợ lý AI tự chủ triển khai ứng dụng

## 1. TỔNG QUAN ĐỀ TÀI
- **Tên đề tài**: Trợ lý AI cho kỹ sư DevOps: Tự động hóa CI/CD
- **Mục tiêu**: Xây dựng hệ thống CI/CD thông minh sử dụng AI Agent (OpenClaw) thay thế Kubernetes phức tạp
- **Kiến trúc tổng thể**: GitHub Actions (CI) → OpenClaw AI Agent (CD) trên VM → Docker Container → Slack ChatOps

## 2. STACK CÔNG NGHỆ
### CI Layer (Cloud)
- GitHub Actions: Build Docker image, push to Docker Hub
- Webhook: Trigger từ GitHub đến OpenClaw

### AI/CD Layer (VM - AWS EC2/Azure VM)
- **OpenClaw**: AI Agent tự chủ (Node.js/Python)
- **Docker**: Container runtime (không dùng Kubernetes)
- **Docker Compose**: Blue-green deployment pattern
- **SQLite**: Lưu trạng thái deployment

### ChatOps Layer
- Slack Bolt Framework (Python/Node.js)
- Slash commands: /deploy, /status, /rollback, /logs
- Interactive buttons: Approve/Reject

## 3. KIẾN TRÚC LUỒNG DỮ LIỆU
1. Developer push code → GitHub
2. GitHub Actions build image → Push Docker Hub
3. GitHub webhook → OpenClaw (thông báo có image mới)
4. OpenClaw quyết định: Auto-deploy hoặc chờ approval
5. OpenClaw thực thi: docker pull → docker run → health check
6. Nếu lỗi: Tự động rollback + phân tích log bằng AI (Claude API)
7. Thông báo kết quả → Slack

## 4. STATE MACHINE CỦA OPENCLAW
- **IDLE**: Chờ webhook
- **DEPLOYING**: Pull image, chạy container mới
- **HEALTH_CHECKING**: Kiểm tra /health endpoint (3 lần, timeout 10s)
- **ACTIVE**: Deploy thành công, traffic chuyển sang
- **ROLLING_BACK**: Health check fail → stop new → start old

## 5. RÀNG BUỘC KỸ THUẬT
- Không dùng Kubernetes (quá phức tạp cho sinh viên)
- Single VM (t3.medium hoặc tương đương)
- Docker Compose cho blue-green (2 container: blue + green)
- Self-hosted: OpenClaw chạy trực tiếp trên VM (không cloud AI)
- Bảo mật: Webhook HMAC signature, Docker non-root, Firewall (22, 80, 443)

## 6. PHÂN CÔNG NHÓM
- **Lộc**: OpenClaw Expert - Viết skills, tích hợp Claude API, State machine
- **Duy**: Infrastructure - VM, Docker, Network, Security, Diagram
- **Khang**: CI/CD - GitHub Actions, Webhook, State API (SQLite)
- **Quyến**: ChatOps - Slack Bot, Documentation, Testing, Tổng hợp

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
- AWS EC2 Docs: docs.aws.amazon.com/ec2
