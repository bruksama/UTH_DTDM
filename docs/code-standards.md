# Code Standards

## Scope

Tài liệu này gộp code standards, documentation standards và design guidelines cho repo.

## Naming

- Tên file dùng kebab-case
- Tên file phải tự mô tả rõ mục đích
- Tài liệu evergreen đặt trong `docs/`
- Kế hoạch và báo cáo đặt trong `plans/`
- Asset nén vào `assets/diagrams/`, `assets/screenshots/`, `assets/logs/` khi cần

## Markdown Rules

- Mỗi file markdown bắt đầu bằng H1 rõ ràng
- Ưu tiên câu ngắn, kỹ thuật, khách quan
- Dùng bảng cho mapping, so sánh, payload, scope
- Phần chưa giải đáp đặt cuối file nếu cần
- Tránh tách quá nhiều file khi nội dung cùng một chủ đề

## Language Rules

- Nội dung chính viết bằng tiếng Việt
- Giữ nguyên thuật ngữ như Container, Health Check, Rollback, Slash Command
- Trích dẫn theo IEEE khi đi vào báo cáo chính thức

## Code Block Rules

- YAML cho GitHub Actions, Docker Compose
- Bash cho script deployment, health check, firewall
- Slack Bot: Python (slack-bolt). State API: Python hoặc Node.js
- Nếu chỉ là minh họa, phải viết rõ phạm vi và assumptions

## Architecture Rules

- Không mở rộng ra Kubernetes hoặc multi-node nếu prompt không yêu cầu
- Kiến trúc mặc định: GitHub Actions -> OpenClaw -> Docker/Nginx -> Slack
- State machine mặc định gồm 5 trạng thái: IDLE, DEPLOYING, HEALTH_CHECKING, ACTIVE, ROLLING_BACK

## Security Rules

- Không đưa secret thật vào repo
- Mô tả secrets management, SSH key-only access
- Ưu tiên non-root Docker và firewall rules rõ ràng

## Diagram Rules

- Diagram đặt tên theo caption dự kiến, ví dụ `hinh-3-1-kien-truc-3-lop`
- Màu ưu tiên: xanh dương cho Docker, tím cho GitHub, cam cho VM/OpenClaw, xanh lá cho success, đỏ cho rollback/error
- Font ưu tiên Arial hoặc Times New Roman
- Hình bắt buộc: architecture, use case, sequence, state machine, blue-green
- Mỗi hình cần caption, số thứ tự liên tục, kích thước dễ đọc trên A4

## Screenshot Rules

- Cắt bỏ thông tin nhạy cảm trước khi đưa vào repo/báo cáo
- Đặt tên file theo ngữ cảnh, ví dụ `slack-status-command-success.png`
- Chỉ giữ screenshot có giá trị minh chứng: workflow run, container state, Slack response, logs

## Report Formatting

- Báo cáo Word: Times New Roman 13pt
- Heading 1/2/3 và caption phải nhất quán
- Ưu tiên nền sáng, contrast rõ, icon đơn giản

## File Size Guidance

- File code mới không nên vượt 200 dòng nếu có thể tách hợp lý
- File markdown nên ngắn gọn, tách khi nó dài và gồm nhiều chủ đề

## Verification Minimum

- Markdown không lỗi syntax
- Cấu trúc file phù hợp `README.md`, `docs/`, `plans/`
- Nội dung không mâu thuẫn với `docs/prompts/`
