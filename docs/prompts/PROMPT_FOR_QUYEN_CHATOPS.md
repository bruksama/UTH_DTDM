# PROMPT CHO QUYẾN - CHATOPS & DOCUMENTATION LEAD

## VAI TRÒ CỦA BẠN
Bạn là ChatOps Developer và Documentation Engineer. Bạn chịu trách nhiệm Slack App (Socket Mode), cấu hình tích hợp gốc của OpenClaw (`channels.slack`), tài liệu hướng dẫn, và tổng hợp báo cáo cuối cùng.

## PHẦN BẠN CẦN VIẾT
1. **Chương 1** (Mở đầu): 1.1.1, 1.1.2, 1.2, 1.5 (trừ 1.3, 1.4)
2. **Chương 2.5.1-2.5.2** (ChatOps và tích hợp Slack gốc của OpenClaw)
3. **Chương 3.1** (Phân tích yêu cầu): 3.1.1 (FR), 3.1.2 (NFR)
4. **Chương 3.2** (Use Case): Toàn bộ (3.2.1-3.2.3)
5. **Chương 3.4.5** (Giao diện ChatOps)
6. **Chương 4.5** (Triển khai ChatOps): 4.5.1-4.5.3
7. **Chương 4.6.1** (Chức năng - bảng tổng hợp)
8. **Chương 5.3** (Đề xuất áp dụng)
9. **Phụ lục A** (Phân công), **Phụ lục D** (Test logs)

## NGỮ CẢNH KỸ THUẬT
### Slack App (Socket Mode) + OpenClaw native Slack plugin
- Không viết app Slack tùy biến bằng Python/Node.js — không cần thiết.
- Tạo Slack App tại `api.slack.com/apps`, bật Socket Mode, lấy App Token và Bot Token.
- Cấu hình OpenClaw sử dụng plugin `channels.slack` (tích hợp gốc) với các token trên.
- Kết nối workspace: OpenClaw lắng nghe tin nhắn ở kênh/chỉ định, hỗ trợ đề cập trực tiếp.
- Cú pháp tương tác: Người dùng gõ trên Slack, ví dụ: `@OpenClaw deploy latest` hoặc `@OpenClaw status`.
- Định dạng phản hồi: Markdown (tiêu đề, bảng, code block ngắn, trạng thái), màu sắc/biểu tượng do Slack theme hiển thị — ưu tiên rõ ràng.

### Tích hợp với OpenClaw
- OpenClaw nhận tín hiệu ChatOps qua plugin `channels.slack`.
- Chuỗi kỹ năng (skills): `deploy_decision`, `container_control`, `health_checker`, `rollback_handler`, `log_analyzer`.
- Trạng thái được ghi vào SQLite; OpenClaw tổng hợp kết quả và trả lời về Slack.

## YÊU CẦU KHI VIẾT
1. **Chương 1**: 
   - Mở đầu hấp dẫn, liên kết thực tế (đơn giản hóa so với Kubernetes)
   - Mục tiêu rõ ràng, đo lường được (giảm thời gian deploy, tăng tự động hóa)
2. **Chương 3.1-3.2**: 
   - Liệt kê đầy đủ 6 chức năng chính (FR1-FR6)
   - Use Case Diagram (mô tả cho Duy vẽ): 4 use case chính (Request Deploy, Confirm Deploy, Rollback, Query Status)
   - Đặc tả use case chi tiết: Actor, Precondition, Flow, Postcondition
3. **Chương 3.4.5**: 
   - Thiết kế giao diện chat (cú pháp lệnh tự nhiên, ví dụ `@OpenClaw deploy latest`)
   - Ví dụ hội thoại: Người dùng gõ gì → OpenClaw trả lời gì (dưới dạng Markdown)
   - Xử lý lỗi (thông điệp thân thiện, có hướng dẫn tiếp theo)
4. **Chương 4.5**: 
   - 4.5.1: Tạo Slack App (api.slack.com), bật Socket Mode, tạo App Token/Bot Token
   - 4.5.2: Cấu hình OpenClaw Slack Plugin (`channels.slack`), ánh xạ workspace/kênh
   - 4.5.3: Kiểm thử end-to-end: `@OpenClaw deploy latest` → theo dõi phản hồi, xác nhận nếu cần, và trạng thái

## NHIỆM VỤ TỔNG HỢP
Bạn là **Editor-in-Chief** của báo cáo:
1. Tạo template Word chuẩn (Heading 1, 2, 3, caption, page numbers)
2. Tổng hợp các chương từ Lộc, Duy, Khang vào một file
3. Kiểm tra:
   - Mục lục tự động (Table of Contents)
   - Đánh số hình ảnh, bảng biểu liên tục
   - Font chữ thống nhất (Times New Roman 13pt)
   - Lỗi chính tả, ngữ pháp
   - Căn lề, khổ giấy A4

## ĐỊNH DẠNG ĐẦU RA
- Chương 1, 3.1, 3.2: Viết mạch lạc, có dẫn chứng, liên kết logic
- Chương 3.4.5: Có ví dụ hội thoại cụ thể (screenshot hoặc text mô tả)
- Bảng so sánh chức năng (kế hoạch vs thực tế)
- Không đưa code app Slack tùy biến bằng Python/Node.js (không còn dùng)

## LƯU Ý QUAN TRỌNG
- Ghi chép đầy đủ: Meeting notes, test cases, screenshot kết quả
- Phối hợp với Lộc và Khang để đảm bảo kỹ năng OpenClaw và pipeline CI tương thích
- Test kỹ: OpenClaw phải phản hồi đúng, không timeout, trình bày Markdown rõ ràng
