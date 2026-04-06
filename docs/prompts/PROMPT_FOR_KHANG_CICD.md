# PROMPT CHO KHANG - CI/CD & STATE ENGINEER

## VAI TRÒ CỦA BẠN
Bạn là CI/CD Engineer và State Management Developer. Bạn chịu trách nhiệm GitHub Actions (build/push) và hệ thống lưu trữ trạng thái (SQLite).

## PHẦN BẠN CẦN VIẾT
1. **Chương 2.1** (CI/CD): 2.1.1-2.1.3
2. **Chương 2.6** (State & Log): 2.6.1-2.6.2
3. **Chương 3.4.1** (CI Layer - GitHub Actions)
4. **Chương 3.4.4** (State Persistence)
5. **Chương 3.5.3-3.5.4** (Secrets Management và bảo mật CI/CD)
6. **Chương 4.2** (Triển khai CI): 4.2.1-4.2.3
7. **Phụ lục E** (Cost analysis - so sánh chi phí)

## NGỮ CẢNH KỸ THUẬT
### GitHub Actions
- Workflow file: `.github/workflows/build-and-push.yml`
- Triggers: `on: push: branches: [main]`
- Jobs: build (docker build), test (optional), push registry
- Secrets: DOCKER_USERNAME, DOCKER_PASSWORD

### Image Handoff
- Handoff qua registry: OpenClaw lấy image tag/digest mới nhất khi có lệnh Slack
- Metadata tối thiểu: `{ "image": "repo:tag", "digest": "sha256:...", "commit": "sha", "build_number": "n" }`

### State Management (SQLite)
- Schema đơn giản:
  - `deployments(id, image_tag, deployed_at, status, container_name, logs)`
  - `current_state(active_container, previous_container, last_health_check)`
- API hoặc service nội bộ đơn giản để OpenClaw query/update

## YÊU CẦU KHI VIẾT
1. **Chương 2.1**: 
   - Giải thích CI/CD pipeline cơ bản (Source → Build → Test → Deploy)
   - Chi tiết GitHub Actions (tại sao chọn GitHub thay vì GitLab/Jenkins - đơn giản, free, tích hợp tốt)
   - Phân biệt CD (Continuous Deployment) vs CDelivery rõ ràng
2. **Chương 3.4.1**: 
   - Cung cấp mẫu file `.github/workflows/build-and-push.yml` (YAML)
   - Giải thích cơ chế build/push và handoff metadata cho OpenClaw
   - Bảo mật secrets trong GitHub Actions và registry
3. **Chương 3.4.4**: 
   - Thiết kế database schema (SQLite)
   - Giải thích tại sao cần state persistence (phục hồi sau restart, audit trail)
   - API endpoints hoặc cách cập nhật state mà OpenClaw sử dụng sau mỗi lệnh deploy
4. **Chương 4.2**: Hướng dẫn cấu hình thực tế trên GitHub (Settings → Secrets)

## ĐỊNH DẠNG ĐẦU RA
- Code blocks cho YAML (GitHub Actions), Python (SQLite/service layer), Bash (docker hoặc registry commands)
- Bảng mô tả metadata image/tag/digest
- Sơ đồ luồng dữ liệu: GitHub push image lên Registry; người vận hành ra lệnh qua Slack ChatOps; OpenClaw đọc metadata và triển khai (text mô tả nếu Duy chưa vẽ xong)

## NHIỆM VỤ BACKUP
- Backup Duy về Docker cơ bản nếu Duy bận design
- Backup Quyến về phần mô tả metadata image và kiểm thử luồng ChatOps nếu cần

## LƯU Ý
- Đảm bảo tính nhất quán với Chương 3.4.2 (OpenClaw) - metadata image phải khớp với luồng Slack ChatOps của Lộc
- Phần cost analysis (Phụ lục E): So sánh chi phí GitHub Actions (free public repo) + GCP C2 VM vs Kubernetes cluster (~$150+/tháng)
