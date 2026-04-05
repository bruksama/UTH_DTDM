# Project Instructions (for Claude)

This repository contains the academic report and documentation only. Demo/source code will live in a separate repository (TBD).

## Final Architecture (Source of Truth)
- CI/CD: GitHub Actions builds and pushes Docker images to a registry. No webhooks are sent.
- Runtime: Single GCP C2 VM (Ubuntu 22.04) running Docker Compose and Nginx for blue-green switch.
- OpenClaw: Runs on the VM and connects natively to Slack via Socket Mode using the built-in `channels.slack` plugin.
- ChatOps: A human types `@OpenClaw deploy latest` in Slack. OpenClaw receives the message and orchestrates deployment via custom skills: `deploy_decision`, `container_control`, `health_checker`, `rollback_handler`, `log_analyzer`. SQLite stores state.

## Hard Rules (do-not-violate)
- Do not hallucinate webhook triggers. OpenClaw is triggered by human ChatOps via Slack.
- Do not suggest writing custom Slack Bolt apps. OpenClaw uses its native Slack plugin (`channels.slack`) with App/Bot Tokens and Socket Mode.
- Do not implement demo code in this repo. This repository is for the academic report and docs only.
- Documentation language: All Markdown files under `docs/` and `README.md` must be in Vietnamese with proper tones. This `CLAUDE.md` is the only file in English.
- File naming: Use kebab-case for new files (self-documenting names).

## Working Guidance
- Source of truth docs: `docs/prompts/*`, `docs/project-overview-pdr.md`, `docs/code-standards.md`, `docs/project-tracker.md`.
- Keep content accurate to the final architecture above; remove or correct stale references (e.g., Slack Bolt, webhooks).
- Prefer concise, high-signal writing; prioritize correctness over completeness.
- When adding examples, ensure they reflect the native OpenClaw Slack integration and the blue-green flow.

## Scope & Boundaries
- In scope (docs only): CI overview, OpenClaw integration, ChatOps flows, Docker Compose blue-green, Nginx switch, SQLite state, diagrams, and setup guides.
- Out of scope (for this repo): Application code, custom Slack Bolt apps, Kubernetes, multi-VM orchestration, production hardening beyond minimal demos.

## Conventions
- Vietnamese with tones for docs except this file.
- Kebab-case file names.
- Keep single files under ~800 LOC for docs; split when approaching size.

## Quick Checklist for Any Edit
- Architecture statements match the “Final Architecture” section.
- No webhook/Bolt/auto-trigger claims beyond human-invoked Slack ChatOps.
- Examples use `@OpenClaw ...` phrasing; no custom slash-command handlers.
- Docs reference the native Slack plugin: `channels.slack`.
- Repo scope reminder: docs/report only; code in a separate repo.
