---
name: deploy-orchestrator
description: Orchestrate Slack-triggered deployment for Dockerized web apps on a single VM: auto-init config/state when missing, resolve image tags from a registry, run blue-green deployment with Docker Compose and Nginx, perform health checks, rollback on failure, persist SQLite state, and return concise operator-facing results.
metadata: {"openclaw":{"os":["linux"],"requires":{"bins":["bash","docker","curl","python3"],"config":["channels.slack"]}}}
---

# Deploy Orchestrator

`deploy-orchestrator` là skill deploy chính cho v1.

Nó được thiết kế cho mô hình:
- human-triggered deploy từ Slack
- single VM
- Docker / Docker Compose
- blue-green switch qua Nginx
- SQLite làm state store

Repo này đang giữ bản authoring của skill ở `openclaw/skills/deploy-orchestrator`.
Khi cài vào OpenClaw thật, copy nguyên folder này vào một skill root được scan hoặc add parent dir vào `skills.load.extraDirs`.

## Khi nào dùng skill này

Dùng skill này khi cần:
- deploy web app bằng Docker image đã được CI build
- resolve `latest` hoặc tag cụ thể từ registry
- chạy health check trước khi switch traffic
- rollback tự động nếu deploy fail
- lấy trạng thái deploy hiện tại

Không dùng skill này cho:
- Kubernetes
- multi-node deployment
- zero-downtime rollout phức tạp nhiều replica
- private registry auth nâng cao ở v1

## Command scope v1

Skill này hỗ trợ logic cho các intent:
- `deploy latest`
- `deploy <tag>`
- `status`

V1 không hỗ trợ rollback thủ công từ Slack.
Rollback chỉ chạy tự động khi deploy fail.

## Skill package layout

```text
{baseDir}/
├── SKILL.md
├── config/
│   ├── deploy-config.example.yaml
│   └── deploy.env.example
├── references/
│   └── sqlite-schema.md
└── scripts/
    ├── common.sh
    ├── deploy.sh
    ├── ensure_init.sh
    ├── init_db.py
    ├── resolve_image.py
    ├── status.sh
```

Runtime state path được resolve khi chạy từ:
- `DEPLOY_SQLITE_PATH`
- `DEPLOY_RUNTIME_DIR`
- `paths.sqlite_db` hoặc `paths.runtime_dir` trong `{baseDir}/config/deploy-config.yaml`

Không nên assume SQLite state luôn nằm dưới `{baseDir}`.

## Cách vận hành

### 1. Auto-init

Khi skill chạy, nếu thiếu config hoặc SQLite DB, hãy chạy:
- `{baseDir}/scripts/ensure_init.sh`

Script này sẽ:
- tạo thư mục runtime nếu thiếu
- copy `deploy-config.example.yaml` và `deploy.env.example` thành file runtime-local nếu chưa có file thật
- set permission chặt cho config/env/runtime DB mới tạo
- tạo SQLite schema nếu DB chưa tồn tại

### 2. Resolve image

- `deploy latest` -> dùng `{baseDir}/scripts/resolve_image.py latest`
- `deploy <tag>` -> dùng `{baseDir}/scripts/resolve_image.py <tag>`

Resolver hiện tại đọc registry settings từ env runtime như `DEPLOY_REGISTRY_PROVIDER`, `DEPLOY_REGISTRY_BASE`, `DEPLOY_REPOSITORY`, `DEPLOY_PACKAGE_NAME`.
Mặc định v1 ưu tiên registry API và fallback an toàn khi không đọc được tag list.

### 3. Deploy flow

Entrypoint chính là `{baseDir}/scripts/deploy.sh`.

Flow chuẩn:
1. chạy `{baseDir}/scripts/ensure_init.sh`
2. resolve image bằng `{baseDir}/scripts/resolve_image.py`
3. đọc state hiện tại bằng `{baseDir}/scripts/status.sh`
4. chọn candidate color từ state hiện tại
5. delegate app-side switch sang `"$DEPLOY_REPO_DIR/scripts/switch.sh"` với candidate color và image tag đã resolve
6. cập nhật SQLite state/history khi thành công
7. nếu lỗi -> rollback tự động qua app repo runtime script và cập nhật state/history

### 4. Health và traffic notes

Các field `health.*` và `traffic.*` trong `{baseDir}/config/deploy-config.example.yaml` là handoff note cho deploy runtime/app repo.
Package skill hiện tại không tự implement health-check loop hay Nginx switch riêng trong `{baseDir}/scripts/`; phần này được delegate sang `"$DEPLOY_REPO_DIR/scripts/switch.sh"`.

## Config

Skill này dùng 2 nguồn cấu hình:
- `.env` cho runtime/env values
- `yaml` cho environment, runtime path, service mapping và install notes

File được track trong repo chỉ là example:
- `{baseDir}/config/deploy-config.example.yaml`
- `{baseDir}/config/deploy.env.example`

File runtime-local được tạo và chỉnh riêng trên máy chạy:
- `{baseDir}/config/deploy-config.yaml`
- `{baseDir}/config/deploy.env`

`.env` chỉ hỗ trợ dòng `KEY=VALUE` đơn giản; shell expression không được execute.

### Config quan trọng cần có
- environment name
- `DEPLOY_REPO_DIR` nếu app repo không nằm ở default `$HOME/.openclaw/workspace/deploy_runtime`
- default registry
- image repository
- compose file path
- nginx config path
- public health URL
- SQLite DB path
- active Nginx container/service name
- candidate service names

Hiện tại các script local consume trực tiếp:
- env overrides trong `{baseDir}/config/deploy.env`
- `environment`
- `paths.runtime_dir`
- `paths.sqlite_db`
- `services.{blue,green}`

Các field khác trong YAML example là handoff/install notes cho runtime layer kế tiếp, không phải tất cả đều được local scripts consume trực tiếp.

## SQLite state

Schema chuẩn tham chiếu ở:
- `{baseDir}/references/sqlite-schema.md`

Skill này dùng SQLite để lưu:
- current state
- deployment history
- deployment lock

## Output expectation

Khi deploy xong, output nên ngắn và rõ:
- image nào được deploy
- candidate color nào đã dùng
- health check pass/fail
- traffic đã switch chưa
- rollback có xảy ra không

Ví dụ:
- `Deploy thành công: ghcr.io/org/app:1.2.3 lên green, health check pass, traffic đã chuyển.`
- `Deploy thất bại: ghcr.io/org/app:1.2.3 fail health check, đã rollback về blue.`

## Khi cần đọc thêm

- SQLite schema: `{baseDir}/references/sqlite-schema.md`
- Config examples: `{baseDir}/config/`
- Actual execution logic: `{baseDir}/scripts/`

## Implementation note

Đây là skill package gần chạy thật cho v1.
Local contract hiện tại cố ý giữ:
- `name: deploy-orchestrator`
- authoring path hiện có trong repo

Deferred tới install phase:
- move/copy folder sang OpenClaw skill root thật hoặc cấu hình `skills.load.extraDirs`
- chỉ thêm `metadata.openclaw.skillKey` nếu runtime install phase chứng minh là cần thiết

Nó chưa xử lý đầy đủ các ca production như:
- private registry auth nâng cao
- nhiều environment chạy song song
- advanced approval workflow
- multi-service dependency graph

Nhưng nó đủ tốt để làm nền cho demo và tiếp tục harden.
