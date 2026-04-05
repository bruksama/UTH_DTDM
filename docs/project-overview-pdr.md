# Project Overview And PDR

## Overview

Đề tài xây dựng hệ thống CI/CD thông minh cho nhóm sinh viên, thay thế Kubernetes phức tạp bằng pipeline gọn hơn: GitHub Actions làm CI, OpenClaw làm AI deployment operator, Docker Compose thực hiện blue-green deployment trên single VM, Slack cung cấp ChatOps. Ưu tiên: báo cáo học thuật là deliverable chính; mã demo sẽ nằm ở repo riêng (tạo sau).

## Problem And Goals

- Vận hành thủ công dễ lỗi, khó rollback, khó theo dõi state.
- Kubernetes quá nặng đối với phạm vi demo học thuật.
- Mục tiêu chính:
  - Tự động hóa luồng push code -> build image -> deploy -> notify
  - Cho phép OpenClaw tự quyết định auto-deploy hoặc đợi approval
  - Hỗ trợ health check, rollback, log analysis
  - Cung cấp `/deploy`, `/status`, `/rollback`, `/logs` qua Slack

## Repo State

- Repo hiện là workspace tài liệu; chưa có source code, test, scripts hay assets demo.
- Input gốc nằm ở `docs/prompts/`.
- Tài liệu đã được compact thành 3 file evergreen trong `docs/`.

## Scope

### In Scope

- GitHub Actions build/push image va gui webhook
- OpenClaw gateway, skills, deploy decision, rollback logic
- Docker Compose blue-green, Nginx reverse proxy, health check
- SQLite luu deployment history va current state
- Slack Bolt cho ChatOps va approval/status flow
- Bao cao hoc thuat, diagram, huong dan cai dat, cost comparison

### Out Of Scope

- Kubernetes production-grade
- Multi-region deployment
- Multi-VM orchestration
- Platform-scale observability va infra management

## Requirements

### Functional

- FR1: Trigger pipeline khi push code
- FR2: Build và publish Docker image
- FR3: Nhận webhook, xác thực, quyết định deploy
- FR4: Health check và auto rollback nếu fail
- FR5: Lưu/truy vấn deployment state và logs
- FR6: Hỗ trợ Slack commands và thông báo kết quả

### Non-Functional

- Đơn giản, dễ demo, hợp ngữ cảnh sinh viên
- Audit được state và kết quả health check
- Bảo mật cơ bản: HMAC, secrets, SSH key only, firewall, non-root Docker
- Tài liệu rõ, có diagram, code block và mapping phân công

## Architecture Snapshot

### Components

| Thành phần | Vai trò |
| --- | --- |
| GitHub Actions | Build image, push registry, gửi webhook |
| OpenClaw Gateway | Nhận webhook, gọi skills, điều phối deployment |
| Skills | `receive_webhook`, `deploy_decision`, `container_control`, `health_checker`, `rollback_handler`, `log_analyzer` |
| Docker Compose | Quản lý `app-blue` và `app-green` |
| Nginx | Chuyển traffic giữa blue và green |
| SQLite | Lưu deployment history và current state |
| Slack Bot | Slash commands, approval, status, logs |

### Main Flow

1. Developer push code lên GitHub.
2. GitHub Actions build image và push registry.
3. Workflow gửi webhook POST tới OpenClaw.
4. OpenClaw xác thực payload, quyết định deploy ngay hoặc đợi approval.
5. Runtime pull image, start container mới, chạy health check.
6. Nếu healthy, Nginx switch upstream sang version mới.
7. Nếu fail, OpenClaw rollback về version trước và phân tích log.
8. Kết quả được ghi vào SQLite và thông báo qua Slack.

### State Machine

`IDLE -> DEPLOYING -> HEALTH_CHECKING -> ACTIVE | ROLLING_BACK`

## Deployment Target

| Thành phần | Cấu hình mục tiêu |
| --- | --- |
| VM | AWS EC2 t3.medium hoặc Azure Standard_B2s |
| OS | Ubuntu 22.04 LTS |
| Runtime | Docker CE, Docker Compose v2, Nginx |
| State store | SQLite |
| ChatOps | Slack Bolt |
| Ports | 22, 80, 443, 8000 |

## Ownership

| Vai trò | Trách nhiệm chính |
| --- | --- |
| Lộc | OpenClaw, AI logic, state machine, rollback |
| Duy | VM, Docker, network, security, diagram |
| Khang | GitHub Actions, webhook, SQLite state, cost |
| Quyến | Slack ChatOps, documentation, tổng hợp báo cáo |

## Deliverables

- Báo cáo đồ án với chapter ownership rõ ràng
- 5 diagram bắt buộc: architecture, use case, sequence, state machine, blue-green
- Mẫu workflow GitHub Actions, payload webhook, SQLite schema, Slack flow
- Scaffold để bổ sung code demo ở vòng tiếp theo

## Resolved Decisions

- **Tech stack**: OpenClaw (cài đặt + viết skills), Slack bot (Python slack-bolt)
- **Repo scope**: Tài liệu/báo cáo only; mã demo ở repo riêng (TBD)
