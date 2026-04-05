# UTH_DTDM

Kho chua tai lieu khoi tao cho de tai: tro ly AI cho ky su DevOps, tu dong hoa CI/CD bang GitHub Actions, OpenClaw, Docker va Slack ChatOps.

## Muc tieu repo

- Tong hop prompt goc thanh bo tai lieu nen de viet bao cao va trien khai demo
- Co dinh ngu canh ky thuat, pham vi, rang buoc va phan cong nhom
- Tao cac tai lieu song song cho kien truc, roadmap, deployment va chuan tai lieu

## Nguon dau vao hien tai

Repo hien tai bat dau tu `docs/prompts/`:

- `PROJECT_CONTEXT.md`: ngu canh tong the cua de tai
- `PROMPT_FOR_DUY_INFRASTRUCTURE.md`: phan infrastructure, security, diagram
- `PROMPT_FOR_KHANG_CICD.md`: phan CI/CD, webhook, SQLite state
- `PROMPT_FOR_LOC_OPENCLAW.md`: phan AI agent, state machine, rollback logic
- `PROMPT_FOR_QUYEN_CHATOPS.md`: phan Slack ChatOps, documentation, tong hop bao cao

## Cau truc sau khi init

```text
.
├── CLAUDE.md
├── README.md
├── docs/
│   ├── code-standards.md
│   ├── project-overview-pdr.md
│   ├── project-tracker.md
│   ├── prompts/
│   └── ...
└── plans/
    └── 20260405-0236-init-from-prompts/
```

## Tai lieu can doc truoc

- `docs/project-overview-pdr.md`: scope, hien trang repo, kien truc, deployment target
- `docs/code-standards.md`: quy tac viet tai lieu, code block, diagram, naming
- `docs/project-tracker.md`: roadmap, trang thai va changelog nho

## Huong phat trien tiep

1. Chot outline bao cao va mapping tung muc cho thanh vien.
2. Them ma nguon demo cho GitHub Actions, OpenClaw gateway, Slack Bolt app va deployment scripts.
3. Tao thu muc asset cho diagram, screenshot, test logs va mau cau hinh.

## Ghi chu

- Repo hien chua co ma nguon ung dung, chu yeu la prompt va tai lieu khoi tao.
- `docs/` da duoc compact lai; `docs/prompts/` giu nguyen lam input goc.
