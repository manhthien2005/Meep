#!/usr/bin/env python3
"""
Block dangerous commands before Claude Code agent executes them.
Listens on PreToolUse (Bash tool). Reads JSON from stdin, prints plain-text
reason to stdout, exits 2 to block or 0 to allow.
"""

from __future__ import annotations

import json
import re
import sys

HARD_BLOCK_PATTERNS: list[tuple[str, str]] = [
    (r"\brm\s+-[rRf]+\s+/(?:\s|$)", "rm -rf / (xóa toàn bộ root)"),
    (r"\brm\s+-[rRf]+\s+\*\s*$", "rm -rf * (xóa toàn bộ thư mục hiện tại)"),
    (r"\brm\s+-[rRf]+\s+~\s*$", "rm -rf ~ (xóa home directory)"),
    (r"\bmkfs\.", "mkfs (format filesystem)"),
    (r"\bdd\s+if=.*of=/dev/[sh]d", "dd ghi vào raw disk device"),
    (r"\bformat\s+[a-zA-Z]:", "Windows format <drive>:"),
    (r"\bdel\s+/[fFsSqQ]+\s+/[fFsSqQ]+", "del /F /S /Q (xóa đệ quy force)"),
    (r"\brmdir\s+/[sSqQ]+", "rmdir /S (xóa thư mục đệ quy)"),
    (r":\(\)\s*\{.*:\|:.*\}\s*;\s*:", "fork bomb"),
]

CONFIRMED_PATTERNS: list[tuple[str, str, str]] = [
    (
        r"\bgit\s+push\s+(?:.*\s)?(?:-f|--force|--force-with-lease)\b.*\b(main|master|production|prod|develop|deploy)\b",
        "git push --force lên protected branch",
        "Thêm `# CONFIRMED-FORCE-PUSH` vào lệnh, HOẶC làm trên feature branch.",
    ),
    (
        r"\bfirebase\s+(?:deploy|firestore:delete|database:remove)\b.*--project[= ](?:.*?)(?:prod|production)",
        "firebase destructive op trên prod project",
        "Thêm `# CONFIRMED-PROD-DEPLOY` sau khi review thủ công.",
    ),
    (
        r"\bgcloud\s+(?:.*\s)?(?:projects\s+delete|sql\s+databases\s+delete|storage\s+rm\s+-r)",
        "gcloud destructive operation",
        "Thêm `# CONFIRMED-GCLOUD-DESTRUCTIVE` vào lệnh.",
    ),
    (
        r"\bnpm\s+(?:publish|unpublish)\b",
        "npm publish/unpublish",
        "Thêm `# CONFIRMED-NPM-PUBLISH` nếu cố ý.",
    ),
    (
        r"\bpub\s+publish\b",
        "dart pub publish",
        "Thêm `# CONFIRMED-PUB-PUBLISH` nếu cố ý.",
    ),
    (
        r"\bgit\s+reset\s+(?:.*\s)?--hard\b",
        "git reset --hard (xóa uncommitted work)",
        "Thêm `# CONFIRMED-RESET-HARD` nếu muốn discard local changes.",
    ),
    (
        r"\bflutter\s+clean\b",
        "flutter clean (bị cấm auto-run)",
        "Thêm `# CONFIRMED-FLUTTER-CLEAN` nếu cố ý wipe build cache.",
    ),
    (
        r"\b(?:npm\s+(?:install|i)|yarn\s+add|pnpm\s+(?:add|install))\s+(?:-[^\s]*\s+)*[a-zA-Z@][^\s]*",
        "npm/yarn/pnpm install <package> (thêm dependency mới)",
        "Thêm `# CONFIRMED-ADD-DEP` sau khi quyết định package + version.",
    ),
    (
        r"\b(?:flutter\s+pub\s+add|dart\s+pub\s+add)\s+[a-zA-Z][^\s]*",
        "flutter/dart pub add <package> (thêm dependency mới)",
        "Thêm `# CONFIRMED-ADD-DEP` sau khi quyết định package + version.",
    ),
    (
        r"\bfirebase\s+auth:(?:export|import)\b",
        "firebase auth:export/import (bulk read/write PII)",
        "Thêm `# CONFIRMED-AUTH-PII` sau khi review security.",
    ),
]

CONFIRM_TOKEN_RE = re.compile(
    r"#\s*CONFIRMED-(?:FORCE-PUSH|PROD-DEPLOY|GCLOUD-DESTRUCTIVE|NPM-PUBLISH|PUB-PUBLISH"
    r"|RESET-HARD|FLUTTER-CLEAN|ADD-DEP|AUTH-PII)\b"
)


def main() -> int:
    try:
        raw = sys.stdin.read()
        data = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        return 0  # fail-open

    # Claude Code PreToolUse Bash: input có dạng {"command": "...", "description": "..."}
    cmd = data.get("command", "") or data.get("tool_input", {}).get("command", "") or ""
    if not cmd.strip():
        return 0

    cmd_norm = cmd.strip()

    for pattern, label in HARD_BLOCK_PATTERNS:
        if re.search(pattern, cmd_norm, flags=re.IGNORECASE):
            print(
                f"CHẶN — lệnh khớp hard-block rule: '{label}'\n"
                f"Lệnh: {cmd_norm}\n"
                f"Lệnh này không bao giờ được auto-chạy. Chạy thủ công trong terminal nếu cố ý."
            )
            return 2

    has_confirm = bool(CONFIRM_TOKEN_RE.search(cmd_norm))
    for pattern, label, hint in CONFIRMED_PATTERNS:
        if re.search(pattern, cmd_norm, flags=re.IGNORECASE) and not has_confirm:
            print(
                f"CHẶN — lệnh khớp rule: '{label}'\n"
                f"Lệnh: {cmd_norm}\n"
                f"Cách unblock: {hint}\n"
                f"Hoặc chạy thủ công trong terminal của anh."
            )
            return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
