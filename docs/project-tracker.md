# Project Tracker

## Current Status

| Phase | Status | Mô tả ngắn |
| --- | --- | --- |
| Phase 0 - Bootstrap docs | Complete | Đã khởi tạo README, CLAUDE và docs nền |
| Phase 1 - Finalize report outline | In Progress | Chốt chapter structure, ownership, references |
| Phase 2 - CI/CD scaffold | Pending | GitHub Actions, container registry, SQLite state API |
| Phase 3 - OpenClaw scaffold | Pending | Gateway, skills, deploy decision, rollback logic |
| Phase 4 - Deployment scaffold | Pending | Docker Compose, Nginx, health check, rollback scripts |
| Phase 5 - ChatOps scaffold | Pending | Slack app, slash commands, approval/status flow |
| Phase 6 - Assets and evidence | Pending | Diagram, screenshot, log mẫu, test evidence |
| Phase 7 - Final report integration | Pending | Tổng hợp báo cáo, review, appendix, cost |

## Immediate Priorities

1. ~~Chốt stack cho OpenClaw gateway và Slack bot.~~ ✓ Resolved: OpenClaw (install + skills), Slack (Python slack-bolt)
2. Chốt registry và state API shape.
3. Chốt công cụ diagram và bộ asset proof.

## Dependencies

- Phase 2 cần quyết định runtime và registry.
- Phase 3 phụ thuộc vào contract từ Phase 2.
- Phase 4 phụ thuộc vào container contract và state machine.
- Phase 5 phụ thuộc vào OpenClaw API/state interface.
- Phase 7 phụ thuộc vào asset và scaffold từ các phase trước.

## Changelog

### 2026-04-05

- Khởi tạo repo documentation-first từ `docs/prompts/`
- Thêm `README.md`, `CLAUDE.md`, plan init và bộ docs nền
- Compact `docs/` từ nhiều file trùng lặp xuống bộ file nhỏ gọn hơn

## Resolved Decisions

- Ưu tiên deliverable: Báo cáo học thuật (academic report)
- Phạm vi repo: Chỉ chứa tài liệu/báo cáo; mã demo sẽ đặt ở repo riêng (TBD)
