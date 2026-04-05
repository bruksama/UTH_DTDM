# Project Instructions

## Project Type

Kho tai lieu va scaffold ban dau cho de tai hoc thuat ve AI DevOps assistant. Hien trang tap trung vao prompt, tai lieu va ke hoach; ma nguon demo se bo sung sau.

## Source Of Truth

- `docs/prompts/PROJECT_CONTEXT.md`
- `docs/prompts/PROMPT_FOR_DUY_INFRASTRUCTURE.md`
- `docs/prompts/PROMPT_FOR_KHANG_CICD.md`
- `docs/prompts/PROMPT_FOR_LOC_OPENCLAW.md`
- `docs/prompts/PROMPT_FOR_QUYEN_CHATOPS.md`
- `docs/project-overview-pdr.md`
- `docs/code-standards.md`
- `docs/project-tracker.md`

## Working Rules

- Uu tien cap nhat file hien co thay vi tao them bien the khong can thiet.
- Giu ten file dang kebab-case, tu mo ta ro muc dich.
- Neu them code sau nay, moi file nen duoi 200 dong neu co the tach logic hop ly.
- Tai lieu va bao cao viet bang tieng Viet ky thuat; thuat ngu chuyen nganh giu nguyen tieng Anh khi can.
- Khong mo rong pham vi vuot qua rang buoc prompt: single VM, Docker Compose blue-green, GitHub Actions, OpenClaw, Slack ChatOps.

## Repo Priorities

1. Chot bo tai lieu nen va outline bao cao.
2. Bo sung implementation scaffold cho CI, AI/CD, ChatOps va deployment.
3. Them diagram, screenshot, log mau va huong dan demo.

## Expected Deliverables

- Tai lieu tong quan va kien truc
- Roadmap va changelog
- Chuan trinh bay, diagram, code block va trich dan
- Scaffold cho phan cong nhom: Infrastructure, CI/CD, OpenClaw, ChatOps

## Unresolved Questions

- Chua co quy uoc ten de tai chinh thuc bang tieng Anh de dung cho code/package names.
- Chua xac dinh stack uu tien cho OpenClaw gateway va Slack app: Node.js hay Python.
