# PROMPT CHO DUY - INFRASTRUCTURE & DESIGN LEAD

## VAI TRÒ CỦA BẠN
Bạn là Infrastructure Engineer và Visual Designer. Bạn chịu trách nhiệm mọi thứ liên quan đến VM, Docker, Network, Security và TẤT CẢ các diagram.

## PHẦN BẠN CẦN VIẾT
1. **Chương 1.3** (Phạm vi và giới hạn - phần infrastructure)
2. **Chương 2.2** (Docker): 2.2.1-2.2.5
3. **Chương 2.3** (VM và Cloud): 2.3.1-2.3.3
4. **Chương 3.4.3** (Container Deployment Strategy): Blue-green, Health Check, Rollback
5. **Chương 3.5** (Bảo mật): 3.5.1-3.5.2 (VM và Docker Security)
6. **Chương 4.1** (Môi trường triển khai): 4.1.1-4.1.3
7. **Chương 4.4** (Triển khai Deployment): 4.4.1-4.4.3 (phần Docker/script)
8. **Phụ lục C** (Hướng dẫn cài đặt - chủ trì)

## NGỮ CẢNH KỸ THUẬT
### Infrastructure Stack
- **VM**: AWS EC2 t3.medium (2 vCPU, 4GB RAM) hoặc Azure Standard_B2s, Ubuntu 22.04 LTS
- **Docker**: Docker CE, Docker Compose v2
- **Network**: Security Groups mở port 22 (SSH), 80 (HTTP), 443 (HTTPS), 8000 (OpenClaw internal)
- **Storage**: 20GB SSD, volumes cho logs và SQLite

### Blue-Green Deployment Pattern
- 2 containers: `app-blue` (current) và `app-green` (new)
- Nginx reverse proxy chuyển traffic giữa 2 container
- Zero-downtime: Start green → Health check → Switch nginx upstream → Stop blue

### Security Requirements
- Không dùng password root (SSH key only)
- Docker non-root user (rootless mode hoặc user namespace)
- Firewall UFW hoặc iptables
- TLS/SSL nếu có domain (Let's Encrypt)

## YÊU CẦU KHI VIẾT
1. **Chương 2.2-2.3**: 
   - Giải thích tại sao chọn VM thay vì Kubernetes (đơn giản, cost-effective, đủ cho sinh viên)
   - Chi tiết Docker Compose cho blue-green (file docker-compose.yml mẫu)
2. **Chương 3.4.3**: 
   - Mô tả chi tiết cơ chế chuyển traffic (nginx config)
   - Health check script (bash hoặc Python đơn giản)
   - Rollback script (docker stop/start)
3. **Chương 3.5**: Liệt kê các biện pháp bảo mật cụ thể (firewall rules, user permissions)
4. **Chương 4.1**: Thông số kỹ thuật chính xác (instance type, disk size, OS version)

## NHIỆM VỤ DESIGN
Bạn phải tạo **5 diagram** (vẽ bằng draw.io/Excalidraw, chèn vào báo cáo):
1. **Hình 3.1**: Sơ đồ kiến trúc 3 lớp (GitHub → OpenClaw → Docker → Slack)
2. **Hình 3.2**: Use Case Diagram (Developer, OpenClaw, GitHub System)
3. **Hình 3.3**: Luồng dữ liệu (Sequence từ push code đến notify)
4. **Hình 3.4**: State Machine (5 trạng thái của OpenClaw)
5. **Hình 3.5**: Blue-Green Deployment Architecture

Yêu cầu hình ảnh:
- Màu sắc thống nhất: Xanh dương (Docker), Tím (GitHub), Cam (VM), Xanh lá (Success), Đỏ (Error)
- Font: Arial hoặc Times New Roman nếu có text
- Resolution: 300 DPI, width 1200-1600px

## ĐỊNH DẠNG ĐẦU RA
- Có bảng so sánh chi phí (VM vs Kubernetes - ước tính)
- Code blocks cho docker-compose.yml, nginx.conf, firewall rules
- Screenshots thực tế (nếu có) hoặc mô tả chi tiết cấu hình

## GHI CHÚ
- Phối hợp với Lộc ở phần 3.4.3 (Rollback) và 4.4.3 để đảm bảo logic AI kết nối đúng với Docker commands
- Backup cho Khang về Docker nếu cần
