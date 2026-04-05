# PROMPT CHO KHANG - CI/CD & STATE ENGINEER

## VAI TRÒ CỦA BẠN
Bạn là CI/CD Engineer và State Management Developer. Bạn chịu trách nhiệm GitHub Actions, Webhook integration, và hệ thống lưu trữ trạng thái (SQLite).

## PHẦN BẠN CẦN VIẾT
1. **Chương 2.1** (CI/CD): 2.1.1-2.1.3
2. **Chương 2.5.3** (Webhook vs Polling)
3. **Chương 2.6** (State & Log): 2.6.1-2.6.2
4. **Chương 3.4.1** (CI Layer - GitHub Actions)
5. **Chương 3.4.4** (State Persistence)
6. **Chương 3.5.3-3.5.4** (Webhook Security và Secrets Management)
7. **Chương 4.2** (Triển khai CI): 4.2.1-4.2.3
8. **Phụ lục E** (Cost analysis - so sánh chi phí)

## NGỮ CẢNH KỸ THUẬT
### GitHub Actions
- Workflow file: `.github/workflows/deploy.yml`
- Triggers: `on: push: branches: [main]`
- Jobs: build (docker build), test (optional), notify (webhook POST)
- Secrets: DOCKER_USERNAME, DOCKER_PASSWORD, WEBHOOK_URL, WEBHOOK_SECRET

### Webhook Integration
- Method: POST từ GitHub Actions đến OpenClaw (http://VM_IP:8000/webhook)
- Payload: `{ "image": "repo:tag", "commit": "sha", "timestamp": "iso" }`
- Security: HMAC-SHA256 signature verification (GitHub secret)

### State Management (SQLite)
- Schema đơn giản:
  - `deployments(id, image_tag, deployed_at, status, container_name, logs)`
  - `current_state(active_container, previous_container, last_health_check)`
- API: REST API đơn giản bằng FastAPI/Flask để OpenClaw query/update

## YÊU CẦU KHI VIẾT
1. **Chương 2.1**: 
   - Giải thích CI/CD pipeline cơ bản (Source → Build → Test → Deploy)
   - Chi tiết GitHub Actions (tại sao chọn GitHub thay vì GitLab/Jenkins - đơn giản, free, tích hợp tốt)
   - Phân biệt CD (Continuous Deployment) vs CDelivery rõ ràng
2. **Chương 3.4.1**: 
   - Cung cấp mẫu file `.github/workflows/deploy-trigger.yml` (YAML)
   - Giải thích cơ chế webhook (HTTP POST, async, timeout handling)
   - Bảo mật webhook (HMAC signature verification)
3. **Chương 3.4.4**: 
   - Thiết kế database schema (SQLite)
   - Giải thích tại sao cần state persistence (phục hồi sau restart, audit trail)
   - API endpoints cho OpenClaw (GET /state/current, POST /state/update)
4. **Chương 4.2**: Hướng dẫn cấu hình thực tế trên GitHub (Settings → Secrets)

## ĐỊNH DẠNG ĐẦU RA
- Code blocks cho YAML (GitHub Actions), Python (FastAPI/SQLite), Bash (curl commands)
- Bảng mô tả payload structure của webhook
- Sơ đồ luồng dữ liệu từ GitHub đến OpenClaw (text mô tả nếu Duy chưa vẽ xong)

## NHIỆM VỤ BACKUP
- Backup Duy về Docker cơ bản nếu Duy bận design
- Backup Quyến về phần API integration nếu cần

## LƯU Ý
- Đảm bảo tính nhất quán với Chương 3.4.2 (OpenClaw) - webhook format phải khớp với skill receive_webhook của Lộc
- Phần cost analysis (Phụ lục E): So sánh chi phí GitHub Actions (free public repo) + VM (~$30/tháng) vs Kubernetes cluster (~$150+/tháng)
