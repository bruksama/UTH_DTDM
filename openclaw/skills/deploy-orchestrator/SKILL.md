---
name: deploy-orchestrator
description: Orchestrate Slack-triggered deployment for Dockerized web apps on a single VM: auto-init config/state when missing, resolve image tags from a registry, run blue-green deployment with Docker Compose and Nginx, perform health checks, rollback on failure, persist SQLite state, and return concise operator-facing results.
metadata:
  openclaw:
    os: ["linux"]
    requires:
      bins: ["bash", "docker", "curl", "python3"]
      config: ["channels.slack"]
---

# Deploy Orchestrator

`deploy-orchestrator` là skill deploy chính cho v1.

Nó được thiết kế cho mô hình:
- human-triggered deploy từ Slack
- single VM
- Docker / Docker Compose
- blue-green switch qua Nginx
- SQLite làm state store

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
deploy-orchestrator/
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
    ├── health_check.sh
    ├── init_db.py
    ├── resolve_image.py
    ├── rollback.sh
    ├── status.sh
    └── switch_traffic.sh
```

## Cách vận hành

### 1. Auto-init

Khi skill chạy, nếu thiếu config hoặc SQLite DB, hãy chạy:
- `scripts/ensure_init.sh`

Script này sẽ:
- tạo thư mục runtime nếu thiếu
- copy config example nếu chưa có config thật
- tạo SQLite schema nếu DB chưa tồn tại

### 2. Resolve image

- `deploy latest` -> dùng `scripts/resolve_image.py latest`
- `deploy <tag>` -> dùng `scripts/resolve_image.py <tag>`

Mặc định v1 ưu tiên registry API.
Hiện tại mặc định registry là `ghcr.io`, nhưng có thể đổi qua config.

### 3. Deploy flow

Flow chuẩn:
1. ensure init
2. resolve image
3. đọc state hiện tại
4. chọn candidate color
5. pull image
6. start candidate bằng Docker Compose
7. health check candidate
8. switch traffic qua Nginx
9. health check public URL sau switch
10. cập nhật SQLite state/history
11. nếu lỗi -> rollback tự động + cập nhật state/history

### 4. Health policy v1

Đã chốt cho v1:
- route kiểm tra: `/`
- retry: `3`
- timeout mỗi lần: `10s`
- pre-switch: check candidate trong Docker network
- post-switch: check public URL sau khi Nginx đổi upstream

### 5. Traffic switch v1

Đã chốt cho v1:
- sửa Nginx upstream active giữa `blue` và `green`
- reload Nginx nếu có thể; fallback restart nếu cần

## Config

Skill này dùng 2 loại config:
- `.env` cho runtime/env values
- `yaml` cho deploy behavior/config tĩnh

Nếu chưa có file thật, copy từ example rồi sửa.

### Config quan trọng cần có
- environment name
- default registry
- image repository
- compose file path
- nginx config path
- public health URL
- SQLite DB path
- active Nginx container/service name
- candidate service names

## SQLite state

Schema chuẩn tham chiếu ở:
- `references/sqlite-schema.md`

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

- SQLite schema: `references/sqlite-schema.md`
- Config examples: `config/`
- Actual execution logic: `scripts/`

## Implementation note

Đây là skill package gần chạy thật cho v1.
Nó chưa xử lý đầy đủ các ca production như:
- private registry auth nâng cao
- nhiều environment chạy song song
- advanced approval workflow
- multi-service dependency graph

Nhưng nó đủ tốt để làm nền cho demo và tiếp tục harden.
