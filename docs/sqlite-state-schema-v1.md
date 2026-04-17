# SQLite State Schema v1 cho UTH_DTDM Demo

Tài liệu này chốt **schema SQLite tối thiểu** cho flow deploy v1 của đề tài.

Mục tiêu:
- đủ để OpenClaw đọc/ghi trạng thái deploy
- đủ để rollback tự động khi deploy fail
- đủ để báo cáo lại trên Slack
- đủ gọn cho single-VM demo

## 1. Nguyên tắc thiết kế

Schema này ưu tiên:
- đơn giản
- dễ query
- dễ debug bằng SQLite CLI
- rõ source of truth
- không over-engineering

Không cố biến SQLite thành event platform phức tạp.

## 2. Những gì hệ thống cần nhớ tối thiểu

Hệ thống cần nhớ 4 nhóm thông tin:
1. **Trạng thái hiện tại**
   - active color hiện tại là gì
   - image nào đang live
2. **Lịch sử deploy**
   - ai yêu cầu deploy
   - deploy image nào
   - kết quả ra sao
3. **Rollback context**
   - khi fail thì rollback về đâu
4. **Operational lock / in-progress info**
   - có deploy nào đang chạy không

## 3. Đề xuất bảng tối thiểu

Schema v1 chỉ cần **3 bảng chính**:
- `deployment_state`
- `deployment_history`
- `deployment_lock`

Có thể chạy được chỉ với 2 bảng đầu, nhưng bảng lock giúp tránh command deploy chồng nhau.

---

## 4. Bảng `deployment_state`

Đây là **source of truth hiện tại**.
Mỗi environment chỉ nên có **1 dòng hiện hành**.

```sql
CREATE TABLE IF NOT EXISTS deployment_state (
  environment TEXT PRIMARY KEY,
  active_color TEXT NOT NULL CHECK (active_color IN ('blue', 'green')),
  active_image_tag TEXT NOT NULL,
  active_image_digest TEXT,
  active_container_name TEXT,
  previous_color TEXT CHECK (previous_color IN ('blue', 'green')),
  previous_image_tag TEXT,
  previous_image_digest TEXT,
  last_deployment_id TEXT,
  status TEXT NOT NULL CHECK (status IN ('active', 'deploying', 'rollback-required', 'error')),
  updated_at TEXT NOT NULL,
  notes TEXT
);
```

### Ý nghĩa field
- `environment`: ví dụ `demo`, `staging`, `production-demo`
- `active_color`: màu đang live sau Nginx
- `active_image_tag`: tag image đang phục vụ traffic
- `active_image_digest`: digest để tăng độ chắc chắn nếu có
- `active_container_name`: ví dụ `app-blue` hoặc `app-green`
- `previous_color`: màu trước lần deploy gần nhất
- `previous_image_tag`: image trước đó để rollback logic tham chiếu
- `previous_image_digest`: digest trước đó nếu có
- `last_deployment_id`: liên kết sang `deployment_history`
- `status`: trạng thái hiện tại của environment
- `updated_at`: thời điểm cập nhật gần nhất
- `notes`: ghi chú ngắn nếu cần

### Tại sao bảng này cần
Vì `deploy-orchestrator` phải biết chắc:
- hiện app nào đang live
- nếu fail thì rollback về đâu
- first deploy đã xảy ra chưa

---

## 5. Bảng `deployment_history`

Đây là bảng ghi lại **mỗi lần deploy attempt**.

```sql
CREATE TABLE IF NOT EXISTS deployment_history (
  deployment_id TEXT PRIMARY KEY,
  environment TEXT NOT NULL,
  requested_by TEXT NOT NULL,
  requested_command TEXT NOT NULL,
  requested_image TEXT NOT NULL,
  resolved_image_tag TEXT,
  resolved_image_digest TEXT,
  previous_active_color TEXT CHECK (previous_active_color IN ('blue', 'green')),
  candidate_color TEXT CHECK (candidate_color IN ('blue', 'green')),
  final_active_color TEXT CHECK (final_active_color IN ('blue', 'green')),
  health_check_url TEXT,
  health_check_passed INTEGER NOT NULL DEFAULT 0,
  rollback_occurred INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL CHECK (
    status IN (
      'pending',
      'running',
      'succeeded',
      'failed',
      'rolled_back',
      'rollback_failed'
    )
  ),
  error_summary TEXT,
  operator_summary TEXT,
  started_at TEXT NOT NULL,
  finished_at TEXT
);
```

### Ý nghĩa field
- `deployment_id`: id duy nhất cho mỗi lần deploy
- `environment`: environment được deploy
- `requested_by`: user Slack hoặc actor đã yêu cầu
- `requested_command`: ví dụ `deploy latest`
- `requested_image`: raw input từ command
- `resolved_image_tag`: tag sau khi resolve
- `resolved_image_digest`: digest sau khi resolve
- `previous_active_color`: màu đang active trước khi deploy
- `candidate_color`: màu được dùng làm candidate
- `final_active_color`: màu cuối cùng sau khi flow xong
- `health_check_url`: URL được check, ví dụ `/` hoặc URL đầy đủ
- `health_check_passed`: 0/1
- `rollback_occurred`: 0/1
- `status`: kết quả tổng quát của deploy attempt
- `error_summary`: lỗi ngắn gọn nếu có
- `operator_summary`: summary trả về Slack hoặc lưu lịch sử
- `started_at`, `finished_at`: thời gian chạy

### Tại sao bảng này cần
Vì đề tài cần:
- lịch sử rõ ràng
- chứng minh rollback có xảy ra không
- trace deploy nào thành công / thất bại

---

## 6. Bảng `deployment_lock`

Bảng này giúp tránh hai lệnh deploy chạy cùng lúc.

```sql
CREATE TABLE IF NOT EXISTS deployment_lock (
  environment TEXT PRIMARY KEY,
  locked_by TEXT NOT NULL,
  deployment_id TEXT NOT NULL,
  lock_reason TEXT,
  locked_at TEXT NOT NULL,
  expires_at TEXT
);
```

### Cách dùng
- trước khi deploy, `deploy-orchestrator` kiểm tra có lock không
- nếu có lock hợp lệ -> reject hoặc báo đang có deploy khác chạy
- khi deploy kết thúc -> xóa lock

### Tại sao nên có
Vì dù demo nhỏ, command Slack vẫn có thể bị gửi liên tiếp.
Bảng này là cách đơn giản để tránh race condition thô.

---

## 7. Index khuyến nghị

```sql
CREATE INDEX IF NOT EXISTS idx_history_environment_started_at
ON deployment_history(environment, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_history_status
ON deployment_history(status);
```

Không cần thêm quá nhiều index cho v1.

---

## 8. Quy ước trạng thái

### `deployment_state.status`
- `active`: trạng thái bình thường
- `deploying`: đang có deploy chạy
- `rollback-required`: deploy lỗi và cần rollback hoặc đang chờ xác minh
- `error`: state bất thường, cần operator kiểm tra

### `deployment_history.status`
- `pending`: vừa tạo record, chưa chạy thật
- `running`: đang deploy
- `succeeded`: deploy thành công
- `failed`: deploy fail nhưng chưa chắc rollback thành công
- `rolled_back`: deploy fail, rollback thành công
- `rollback_failed`: deploy fail và rollback cũng fail

---

## 9. Bootstrap rule cho first deploy

Vì Master đã chốt first deploy vào `blue`, rule cho first deploy là:
- nếu `deployment_state` chưa có dòng cho environment hiện tại:
  - coi là bootstrap deploy
  - candidate = `blue`
  - sau khi thành công:
    - `active_color = blue`
    - `previous_color = NULL`
    - `status = active`

---

## 10. Mapping với các quyết định đã chốt

### 1D — resolve image
- `requested_image` lưu raw input (`latest` hoặc `<tag>`)
- `resolved_image_tag` và `resolved_image_digest` lưu kết quả resolve thực tế

### 2A — switch traffic qua Nginx
- `active_color` và `final_active_color` phản ánh container đang được Nginx trỏ tới

### 3D — health check route public
- `health_check_url` lưu route được check
- v1 có thể lưu `/` hoặc URL đầy đủ

### 4A — bootstrap vào blue
- xử lý bằng logic first deploy + `deployment_state`

### 5B — không rollback thủ công từ Slack
- schema không cần bảng riêng cho manual rollback command
- chỉ cần `rollback_occurred` + `status`

---

## 11. Query mẫu

### Lấy trạng thái hiện tại
```sql
SELECT *
FROM deployment_state
WHERE environment = 'demo';
```

### Lấy 5 deploy gần nhất
```sql
SELECT deployment_id, requested_by, requested_command, resolved_image_tag, status, started_at
FROM deployment_history
WHERE environment = 'demo'
ORDER BY started_at DESC
LIMIT 5;
```

### Lấy deploy gần nhất thành công
```sql
SELECT *
FROM deployment_history
WHERE environment = 'demo'
  AND status = 'succeeded'
ORDER BY started_at DESC
LIMIT 1;
```

### Kiểm tra có deploy đang chạy không
```sql
SELECT *
FROM deployment_lock
WHERE environment = 'demo';
```

---

## 12. Kết luận

Schema này là đủ cho v1 vì nó giải quyết được các câu hỏi quan trọng nhất:
- hiện tại màu nào đang live?
- image nào đang live?
- deploy vừa rồi thành công hay thất bại?
- có rollback không?
- nếu cần rollback thì reference trước đó là gì?
- có deploy khác đang chạy không?

Nếu sau này mở rộng, có thể thêm:
- bảng `deployment_events`
- bảng `approval_requests`
- bảng `health_check_results`
- bảng `log_analysis_results`

Nhưng với demo hiện tại, chưa cần.
