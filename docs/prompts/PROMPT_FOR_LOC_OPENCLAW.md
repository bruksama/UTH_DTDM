# PROMPT CHO LỘC - OPENCLAW EXPERT & AI ARCHITECT

## VAI TRÒ CỦA BẠN
Bạn là chuyên gia OpenClaw và AI Architect. Bạn chịu trách nhiệm các phần cốt lõi về AI Agent, State Machine, và Integration.

## PHẦN BẠN CẦN VIẾT
1. **Chương 2.4** (AI Agent và OpenClaw): 2.4.1, 2.4.2, 2.4.3
2. **Chương 3.4.2** (AI Deployment Agent): QUAN TRỌNG NHẤT - State machine, 6 skills
3. **Chương 3.3.1** (phần AI), 3.3.2 (phần AI)
4. **Chương 4.3** (Triển khai OpenClaw): 4.3.1-4.3.4
5. **Chương 4.4.3** (Rollback Automation - phần AI logic)
6. **Chương 4.5.3** (Kết nối Bolt-OpenClaw)
7. **Chương 4.6.3** (Hạn chế - giới hạn AI)
8. **Chương 5** (Kết luận - phần 5.1, 5.2)

## NGỮ CẢNH CHI TIẾT VỀ OPENCLAW
- OpenClaw là AI Agent tự chủ (autonomous), không phải chatbot thông thường
- Triển khai: Cài đặt OpenClaw hiện có (không tự phát triển gateway), cấu hình Gateway và tập trung vào Skills (Markdown) + Tools (Shell, Browser, File, Cron, Webhook)
- Chạy 24/7, có long-term memory, tự động hoàn thành tác vụ
- Skills cần viết: receive_webhook, deploy_decision, container_control, health_checker, rollback_handler, log_analyzer
- Tích hợp Claude API (Anthropic) để phân tích log và đưa ra quyết định

## YÊU CẦU KHI VIẾT
1. **Chương 2.4**: Giải thích rõ OpenClaw khác chatbot thường ở đâu (autonomous, tool use, memory)
2. **Chương 3.4.2**: 
   - Mô tả chi tiết State Machine (5 states: IDLE → DEPLOYING → HEALTH_CHECKING → ACTIVE/ROLLING_BACK)
   - Liệt kê 6 skills cụ thể và chức năng từng skill
   - Giải thích cơ chế "quyết định" của AI (khi nào auto-deploy, khi nào chờ approve)
3. **Chương 4.3**: Cung cấp code/config thực tế (có thể là pseudocode nhưng chi tiết)
4. **Highlight**: OpenClaw không chỉ là "trigger" mà là "operator" có khả năng quyết định thực sự

## ĐỊNH DẠNG ĐẦU RA
- Sử dụng bảng để so sánh trước/sau khi có AI
- Có sơ đồ State Machine (mô tả bằng text nếu chưa có hình)
- Code blocks cho skills (markdown format của OpenClaw)
- Ví dụ cụ thể: "Khi container crash với lỗi OOM, OpenClaw sẽ..."

## LƯU Ý QUAN TRỌNG
- Nhấn mạnh tính "tự chủ" (autonomous) - agent tự quyết định không cần người can thiệp liên tục
- Đề cập đến RAG (Retrieval-Augmented Generation) nếu dùng vector DB cho log analysis
- Bảo mật: Không expose chi tiết API key trong báo cáo, chỉ mô tả cách lưu trữ an toàn
