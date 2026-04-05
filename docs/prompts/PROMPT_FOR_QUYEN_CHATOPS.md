# PROMPT CHO QUYẾN - CHATOPS & DOCUMENTATION LEAD

## VAI TRÒ CỦA BẠN
Bạn là ChatOps Developer và Documentation Engineer. Bạn chịu trách nhiệm Slack Bot, tài liệu hướng dẫn, và tổng hợp báo cáo cuối cùng.

## PHẦN BẠN CẦN VIẾT
1. **Chương 1** (Mở đầu): 1.1.1, 1.1.2, 1.2, 1.5 (trừ 1.3, 1.4)
2. **Chương 2.5.1-2.5.2** (ChatOps và Slack Bolt)
3. **Chương 3.1** (Phân tích yêu cầu): 3.1.1 (FR), 3.1.2 (NFR)
4. **Chương 3.2** (Use Case): Toàn bộ (3.2.1-3.2.3)
5. **Chương 3.4.5** (ChatOps Interface)
6. **Chương 4.5** (Triển khai ChatOps): 4.5.1-4.5.3
7. **Chương 4.6.1** (Chức năng - bảng tổng hợp)
8. **Chương 5.3** (Đề xuất áp dụng)
9. **Phụ lục A** (Phân công), **Phụ lục D** (Test logs)

## NGỮ CẢNH KỸ THUẬT
### Slack Bolt Framework
- Language: Python (slack-bolt) — lựa chọn chính thức
- Socket Mode: Cho phép chạy behind firewall (VM không cần public IP static)
- Slash Commands: 
  - `/deploy [image-tag]` - Deploy thủ công
  - `/status` - Xem trạng thái container
  - `/rollback` - Quay lại version trước
  - `/logs [lines]` - Xem log (mặc định 50 dòng)
- Interactive Components: Buttons (Approve Deploy, View Logs), Select menus

### Integration với OpenClaw
- 2 cách kết nối:
  1. Slack Bot gọi OpenClaw API (HTTP)
  2. Shared SQLite (cùng đọc/ghi database với Khang)
- Message format: Rich text (markdown), color coding (xanh lá success, đỏ error, vàng warning)

## YÊU CẦU KHI VIẾT
1. **Chương 1**: 
   - Mở đầu hấp dẫn, liên kết thực tế (sinh viên gặp khó khăn với K8s)
   - Mục tiêu rõ ràng, đo lường được (giảm thời gian deploy, tăng tự động hóa)
2. **Chương 3.1-3.2**: 
   - Liệt kê đầy đủ 6 chức năng chính (FR1-FR6)
   - Use Case Diagram (mô tả cho Duy vẽ): 4 use case chính (Auto-deploy, Manual Deploy, Auto-rollback, Query Status)
   - Đặc tả use case chi tiết: Actor, Precondition, Flow, Postcondition
3. **Chương 3.4.5**: 
   - Thiết kế giao diện chat (command syntax)
   - Ví dụ dialog: User gõ gì → Bot trả lời gì
   - Xử lý lỗi (error messages thân thiện)
4. **Chương 4.5**: 
   - Hướng dẫn tạo Slack App (api.slack.com/apps)
   - Cấu hình Slash Commands, OAuth scopes (chat:write, commands, v.v.)
   - Code mẫu Bolt app (xử lý command đơn giản)

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
- Chương 3.4.5: Có ví dụ cụ thể (screenshot hoặc text mô tả dialog)
- Code blocks cho Python/Node.js (Bolt framework)
- Bảng so sánh chức năng (kế hoạch vs thực tế)

## LƯU Ý QUAN TRỌNG
- Chăm chỉ ghi chép từ đầu: Meeting notes, test cases, screenshot kết quả
- Backup cho Khang về phần API nếu cần
- Phối hợp với Lộc ở phần 4.5.3 để đảm bảo Slack kết nối đúng với OpenClaw
- Test kỹ: Bot phải respond đúng, không timeout, message format đẹp
