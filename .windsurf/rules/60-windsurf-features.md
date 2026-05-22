---
trigger: manual
description: Windsurf/Cascade features cheatsheet — workflows, skills, MCP setup, hooks, rule modes. Load when user asks about Windsurf features/setup, or when agent needs to suggest a Windsurf-native workflow.
---

# Windsurf / Cascade Features Cheatsheet

> Windsurf có nhiều tính năng native mà em phải tận dụng để tiết kiệm token và làm nhanh hơn. File này nhắc em (và anh) các surface chính.

## Rule activation modes (Windsurf)

Windsurf dùng frontmatter trong `.windsurf/rules/*.md`:

| Mode | Frontmatter | Khi nào |
|---|---|---|
| **Always On** | `trigger: always_on` | Load mỗi message — cho rule core (operating mode, project context, security). |
| **Glob-scoped** | `trigger: glob` + `globs: <pattern>` | Tự load khi file match được mở/edit — cho stack-specific rule (Flutter, Functions). |
| **Manual** | `trigger: manual` | Chỉ load khi user gọi tên rule trong chat — cho reference hiếm dùng. |

**Meep dùng:**
- `trigger: always_on` — `00`, `05`, `10`, `20`, `25`, `30`, `40`, `50`
- `trigger: glob` — `21` (Flutter), `22` (Functions), `23` (Firestore), `24` (UI patterns)
- `trigger: manual` — `60` (file này)

## Skills system (Windsurf)

- Skills nằm ở `.windsurf/skills/<name>/SKILL.md`.
- Cascade đọc `description:` trong frontmatter để biết khi nào invoke.
- Em invoke bằng cách read `SKILL.md` đó **trước khi** làm task tương ứng.
- User có thể request trực tiếp bằng tên skill trong chat.

**Skills hiện có (11):**
- `tdd`, `systematic-debugging`, `verification-before-completion` — discipline
- `karpathy-guidelines`, `brainstorming`, `writing-plans` — methodology
- `code-review-five-axis` — review framework
- `flutter-firebase-patterns`, `nodejs-ts-backend` — stack patterns
- `figma-to-flutter` — Figma → Flutter widget (strict design token mapping)
- `caveman-vi` — opt-in compressed mode

## Workflows / Slash commands (Windsurf)

Workflows nằm ở `.windsurf/workflows/*.md`. Cascade dùng `description:` field để tự match.

| Command | File | Khi nào |
|---|---|---|
| `/start <issue-id>` | `workflows/start.md` | Kickoff task mới từ GitHub issue |
| `/spec` | `workflows/spec.md` | Viết PRD/spec cho feature mới |
| `/plan` | `workflows/plan.md` | Chia spec → ordered task list |
| `/build` | `workflows/build.md` | TDD cycle implement task |
| `/test` | `workflows/test.md` | Write/extend tests |
| `/review` | `workflows/review.md` | 5-axis self review trước PR |
| `/debug` | `workflows/debug.md` | Systematic root cause investigation |
| `/fix-issue` | `workflows/fix-issue.md` | Fix specific GitHub issue end-to-end |
| `/deploy` | `workflows/deploy.md` | Deploy workflow với pre-flight checklist |

## Hooks (project-level)

`.windsurf/hooks.json` chạy script Python để guard agent action:

| Hook | Script | Mục đích |
|---|---|---|
| `pre_run_command` | `block_dangerous_commands.py` | Block `rm -rf /`, `git push --force` lên main, `firebase deploy prod`, etc. |
| `pre_read_code` | `protect_secrets.py` | Block đọc `.env`, `*.pem`, service account JSON, ... |
| `pre_write_code` | `protect_secrets.py` | Block ghi vào file secret. |

**Nếu hook block** → em phải dừng + báo anh, không được bypass.

## MCP servers (Windsurf)

Windsurf đọc MCP từ **user-level** (không phải workspace-level):
- **Path:** `~/.codeium/windsurf/mcp_config.json` (Windows: `C:\Users\<you>\.codeium\windsurf\mcp_config.json`)
- Template commit trong repo: `.windsurf/mcp_config.example.json`

**Setup:**
```pwsh
# 1. Copy template ra user-level
Copy-Item .windsurf\mcp_config.example.json "$env:USERPROFILE\.codeium\windsurf\mcp_config.json"

# 2. Edit file: điền GitHub PAT thật vào chỗ ghp_REPLACE_...
# 3. Restart Windsurf → MCP panel reload.
```

**MCPs hiện tại enable cho Meep:**

| MCP | Mục đích |
|---|---|
| `context7` | Live docs cho Flutter, Firebase, Riverpod, freezed — prevents hallucinating outdated APIs |
| `github` | Issues, PRs, repos, code search, workflows |
| `figma-mcp-go` | Figma frame → code (bridge qua plugin, không cần API key) |

**KHÔNG enable:** `filesystem`, `memory`, `postgres` — ops surface quá lớn cho 4-dev capstone.

## Custom @Docs trong Windsurf

Cascade có thể index docs phổ biến. Anh có thể add docs riêng qua Windsurf Settings.

**Khuyến nghị add cho Meep (Android-only, ADR-0002):**

| Doc | URL |
|---|---|
| Riverpod 2 | `https://riverpod.dev/` |
| Riverpod code-gen | `https://riverpod.dev/docs/concepts/about_code_generation` |
| Flutter CustomPainter | `https://api.flutter.dev/flutter/rendering/CustomPainter-class.html` |
| home_widget package | `https://pub.dev/packages/home_widget` |
| Android AppWidget | `https://developer.android.com/develop/ui/views/appwidgets/overview` |
| Firebase Functions v2 | `https://firebase.google.com/docs/functions/2nd-gen-upgrade` |
| Firestore Security Rules | `https://firebase.google.com/docs/firestore/security/rules-conditions` |

Diary feature cần canvas draw → Flutter CustomPainter doc là core. KHÔNG add iOS WidgetKit / Apple Sign-In (defer per ADR-0002).

## Team onboarding cho `.windsurf/`

Mọi thứ trong `.windsurf/` (trừ `mcp_config.json` thật) đều commit git. Team member mới chỉ cần:

```pwsh
# 1. Pull repo về
git clone <repo>

# 2. Copy MCP template → user-level path + điền token
Copy-Item .windsurf\mcp_config.example.json "$env:USERPROFILE\.codeium\windsurf\mcp_config.json"
# Edit file: thay ghp_REPLACE_... bằng GitHub PAT cá nhân

# 3. (Optional) Figma MCP — download plugin.zip từ GitHub, import vào Figma Desktop

# 4. Restart Windsurf → done
```

## Token discipline khi dùng Windsurf

- **Đính file cụ thể** (cite `@file`) thay vì ask thứ mơ hồ cho task định scope rõ.
- **Tránh đọc file > 1000 dòng full** — dùng `grep` hoặc read với offset/limit.
- **Tận dụng glob-scoped rules** — không cần nhắc lại nội dung Flutter rules khi đang edit Dart file.

Xem thêm `50-token-discipline.md`.

## Windsurf-specific anti-patterns

| Anti-pattern | Vì sao xấu |
|---|---|
| Không invoke skill khi task match `description` | Skill là discipline, không phải optional. |
| Edit `.windsurf/rules/*.md` trong feature branch | Infra file — phải ở `chore/` branch (xem `00-personal-operating-mode.md`). |
| Copy MCP token vào `.windsurf/mcp_config.example.json` và commit | Secret leak — file example gitignored hay không gitignored đều nguy hiểm. User-level path thôi. |
| Dùng `pre_write_code` hook bypass với env var | Hook có lý do — discuss với anh trước. |
