---
name: log-analyzer
description: Analyze deployment or rollback failures for Dockerized web apps on a single VM: collect relevant logs, extract likely failure categories, summarize evidence, and generate concise operator-facing diagnostics for Slack.
metadata: {"openclaw":{"os":["linux"],"requires":{"bins":["bash","docker","python3"],"config":[]}}}
---

# Log Analyzer

`log-analyzer` là skill phụ cho v1.

Repo này đang giữ bản authoring của skill ở `openclaw/skills/log-analyzer`.
Khi cài vào OpenClaw thật, copy nguyên folder này vào một skill root được scan hoặc add parent dir vào `skills.load.extraDirs`.

Nó không điều khiển deploy flow chính.
Vai trò của nó là:
- đọc log liên quan đến deploy/rollback
- gom evidence ngắn gọn
- suy luận nguyên nhân khả dĩ nhất ở mức thận trọng
- tạo summary ngắn cho operator

## Khi nào dùng skill này

Dùng skill này khi:
- deploy fail
- health check fail
- traffic switch fail
- rollback fail
- operator muốn giải thích ngắn gọn vì sao deploy thất bại

Không cần gọi skill này cho mọi deploy thành công bình thường.

## Skill package layout

```text
{baseDir}/
├── SKILL.md
└── scripts/
    ├── analyze_logs.py
    ├── collect_logs.sh
    └── summarize.sh
```

## Cách vận hành

### 1. Collect logs

Dùng:
- `{baseDir}/scripts/collect_logs.sh`

Script này nhận parameter trực tiếp, ví dụ:
- `{baseDir}/scripts/collect_logs.sh --line 100 --candidate app-green --active app-blue --nginx nginx ./log-bundle`

Nó sẽ lấy log từ các nguồn chính như:
- candidate container
- active/previous container nếu cần
- Nginx container nếu có

Mặc định chỉ lấy phạm vi hẹp, không đọc vô hạn.

### 2. Analyze

Dùng:
- `{baseDir}/scripts/analyze_logs.py`

Script này nhận một thư mục bundle log và cố gắng phân loại lỗi theo các nhóm thực dụng của v1.

### 3. Summarize

Dùng:
- `{baseDir}/scripts/summarize.sh`

Script này tạo output ngắn gọn để trả về cho operator.

## V1 analysis categories

Ít nhất nên nhận diện được:
- image pull failure
- port binding conflict
- missing env/config/secrets
- application crash
- health check failure
- nginx/reverse-proxy failure
- insufficient evidence

Nếu evidence không khớp rule chuyên biệt, analyzer trả về `insufficient_evidence`.

## Output expectation

Output nên có:
- incident type
- suspected root cause
- confidence (`high` / `medium` / `low`)
- evidence snippets
- operator guidance ngắn
- slack summary ngắn

Ví dụ:
- `Deploy fail trên green: app không bind được port, nghi ngờ conflict với tiến trình hiện có.`
- `Deploy fail trên green: route / trả 500 sau 3 lần thử, nghi ngờ app crash hoặc thiếu config runtime.`

## Parameters

`log-analyzer` nên ưu tiên parameter thay vì config file riêng.

Các parameter hữu ích cho v1:
- `--line <n>`: số dòng log cần lấy, ví dụ `--line 100`
- `--candidate <container>`: container candidate
- `--active <container>`: container active/previous
- `--nginx <container>`: container Nginx/reverse proxy
- `--bundle <dir>`: thư mục log bundle đã collect

Ví dụ:
- `/log-analyzer --line 100`
- `/log-analyzer --line 150 --candidate app-green --active app-blue --nginx nginx`

Nếu parameter không được truyền đủ, script có thể fallback sang default hợp lý.

## Implementation note

Đây là package analyzer thực dụng cho demo.
Local contract hiện tại cố ý giữ:
- `name: log-analyzer`
- authoring path hiện có trong repo

Deferred tới install phase:
- move/copy folder sang OpenClaw skill root thật hoặc cấu hình `skills.load.extraDirs`
- chỉ thêm `metadata.openclaw.skillKey` nếu runtime install phase chứng minh là cần thiết

Nó không thay thế full observability stack hay log platform.
Nó chỉ cần đủ tốt để:
- hỗ trợ operator
- giải thích lỗi trong demo
- làm rõ vai trò AI trong phần diagnostics

Với v1, thiết kế parameter-driven là phù hợp hơn config file riêng vì:
- gọn hơn
- dễ gọi từ command/skill input
- ít file phải quản lý hơn
