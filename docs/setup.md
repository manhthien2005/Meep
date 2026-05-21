# Setup Guide — Meep

> Tài liệu setup môi trường dev cho Meep. Tách khỏi `AGENTS.md` để giảm context bloat cho AI agent (setup info là one-time, không cần load mỗi message).

## 1. Tooling currently installed

| Tool | Status | Notes |
|---|---|---|
| Flutter 3.41.4 | ✅ Stable channel | |
| Node 22.17.0 | ✅ Local | CI + Cloud Functions runtime = **Node 20**. Test BE features với Node 20 trước khi push tránh CI fail. |
| Git 2.51 | ✅ | |
| Java 21 LTS | ✅ | Android dev |
| Python 3.13.4 | ✅ | Used by hooks |
| Firebase CLI | ❌ | `npm install -g firebase-tools` |
| flutterfire CLI | ❌ | `dart pub global activate flutterfire_cli` |
| MCP servers | ❌ | Xem §3 |
| RTK (token-killer) | ❌ Optional | Xem §4 |

## 2. One-time setup commands

```bash
# Firebase CLI + login
npm install -g firebase-tools
firebase login

# flutterfire CLI (wire google-services.json)
dart pub global activate flutterfire_cli

# Flutter app deps + code generation
cd apps/mobile
flutter pub get
flutterfire configure --project=<your-firebase-project-id>
dart run build_runner build --delete-conflicting-outputs
cd ../..

# Functions deps
cd firebase/functions
npm install
cd ../..

# Project alias
cp firebase/.firebaserc.example firebase/.firebaserc
# Edit firebase/.firebaserc với project IDs thật

# Local env
cp .env.example .env
# Edit .env

# Smoke test the emulator suite
firebase emulators:start --project default
```

## 3. MCP servers — curated minimal set

**Cursor** đọc MCP servers từ:

- **Workspace-level (preferred for team):** `.cursor/mcp.json` ở repo root. Copy từ `.cursor/mcp.example.json` (committed) → `.cursor/mcp.json` (gitignored).
- **User-level:** `C:\Users\<you>\.cursor\mcp.json` (Windows) / `~/.cursor/mcp.json` (macOS/Linux).

### Activate Cursor workspace MCP

```pwsh
# Windows
Copy-Item .cursor\mcp.example.json .cursor\mcp.json
```

```bash
# macOS / Linux
cp .cursor/mcp.example.json .cursor/mcp.json
```

Edit `.cursor/mcp.json`: thay `ghp_REPLACE_WITH_YOUR_PAT` + `figd_REPLACE_WITH_YOUR_FIGMA_TOKEN` bằng token thật. Restart Cursor → MCP panel reload.

### Enabled by default

- **context7** — up-to-date library docs (Flutter / Firebase / Riverpod / freezed). Free tier, no API key.
- **github** — official `ghcr.io/github/github-mcp-server`. Issues, PRs, repos, code search. Requires Docker + GitHub PAT (scopes: `repo`, `read:org`, `read:user`, `workflow`). Alternative remote: `https://api.githubcopilot.com/mcp/`.
- **figma** — `figma-developer-mcp` (GLips). Figma frame URL → layout/text/colors → agent generates Flutter widget. Requires `FIGMA_API_KEY`.

`.cursor/mcp.json` is gitignored — mỗi dev tự fill token. Never commit file thật.

### Deliberately NOT enabled

| MCP | Lý do skip |
|---|---|
| `filesystem` | Redundant — Cursor đã có read/write/edit/grep natively. |
| `memory` | Redundant — Cursor có built-in Memories (GA từ 1.2). |
| `postgres` | Project dùng Firestore (ADR-0001). |
| `firebase` | Chưa có audited official server (2026-04). Dùng `firebase` CLI trực tiếp. |

### Windsurf user (legacy)

Nếu dev dùng Windsurf thay vì Cursor: copy `.windsurf/mcp_config.example.json` → `~/.codeium/windsurf/mcp_config.json` (user-level, không có workspace-level). Chỉ recommend cho ai chưa migrate Cursor.

## 4. RTK (Rust Token Killer) — optional

RTK proxies shell commands và compress noisy output trước khi vào agent context (60–90% token saving trên `git status`, test runners). Chưa install — rule `50-token-discipline.mdc` đã có fallback flags cho noisy commands.

### Option 1 — Pre-built binary (fastest)

1. Download `rtk-x86_64-pc-windows-msvc.zip` từ [releases page](https://github.com/rtk-ai/rtk/releases).
2. Extract `rtk.exe` → `C:\Users\<user>\.local\bin\`.
3. Add folder vào PATH.
4. Restart IDE, verify `rtk --version`.
5. Activate: `rtk init --agent cursor` (hoặc `--agent windsurf`).

### Option 2 — Cargo

```pwsh
winget install Rustlang.Rustup
rustup default stable
cargo install --git https://github.com/rtk-ai/rtk
rtk init --agent cursor
```

### Option 3 — WSL

Linux native, full hook system. Xem [docs](https://github.com/rtk-ai/rtk#windows).

## 5. Source kits (reference only)

`.agent-kits/` folder (gitignored) chứa 7 cloned reference repos. Inspected khi bootstrap project. **Do not edit anything inside `.agent-kits/`.** Nếu cần update skill → edit trực tiếp `.cursor/skills/` (hoặc `.windsurf/skills/`).

| Folder | Origin | Used for |
|---|---|---|
| `superpowers/` | obra/superpowers | Methodology skills: TDD, systematic-debugging, verification, brainstorming, writing-plans |
| `class-ai-agent/` | bahdotsh/class-ai-agent | Slash-command scaffolds (rewritten for Flutter/Firebase) |
| `andrej-karpathy-skills/` | karpathy | `karpathy-guidelines` skill |
| `caveman/` | JuliusBrussee/caveman | Format reference + adapted thành `caveman-vi` |
| `everything-claude-code/` | hesreallyhim | Inspected (Claude-Code plugin system, not portable) |
| `mattpocock-skills/` | mattpocock | Inspected (overlap với superpowers) |
| `rtk/` | rtk-ai/rtk | Documented install path |

Folder ~150 MB. Safe to delete: `Remove-Item -Recurse -Force .agent-kits`.

## 6. Restart checklist sau mọi setup

- [ ] Restart Cursor (hoặc Windsurf) sau khi add MCP/skill/rule mới.
- [ ] Verify `gh auth status` → authenticated.
- [ ] Verify `firebase projects:list` → có project staging + prod.
- [ ] Run `flutter doctor` → no errors.
- [ ] Run `firebase emulators:start` → smoke test.
