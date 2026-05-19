#!/usr/bin/env python3
"""
Block dangerous commands before Cursor agent executes them.

Listens on Cursor's `beforeShellExecution` hook. Reads JSON from stdin,
returns JSON to stdout (and exit code 2 to block).

Project-scoped — blocks only the most destructive patterns. The user can still
run any command in their own terminal; this guards Cursor's auto-execution.

If Python is missing, the hook fails with a non-2 exit code → Cursor proceeds
(fail-open per docs). Graceful degradation, does not break workflow.

Mirrors `.windsurf/hooks/block_dangerous_commands.py` behavior.
"""

from __future__ import annotations

import json
import re
import sys

# ---- Patterns that are ALWAYS blocked (no override) -----------------------
HARD_BLOCK_PATTERNS: list[tuple[str, str]] = [
    (r"\brm\s+-[rRf]+\s+/(?:\s|$)", "rm -rf / (recursive root delete)"),
    (r"\brm\s+-[rRf]+\s+\*\s*$", "rm -rf * (recursive cwd wipe)"),
    (r"\brm\s+-[rRf]+\s+~\s*$", "rm -rf ~ (home directory wipe)"),
    (r"\bmkfs\.", "mkfs (filesystem format)"),
    (r"\bdd\s+if=.*of=/dev/[sh]d", "dd to raw disk device"),
    (r"\bformat\s+[a-zA-Z]:", "Windows format <drive>:"),
    (r"\bdel\s+/[fFsSqQ]+\s+/[fFsSqQ]+", "del /F /S /Q (recursive force delete)"),
    (r"\brmdir\s+/[sSqQ]+", "rmdir /S (recursive directory delete)"),
    (r":\(\)\s*\{.*:\|:.*\}\s*;\s*:", "fork bomb"),
]

# ---- Patterns that require explicit user confirmation token ----------------
CONFIRMED_PATTERNS: list[tuple[str, str, str]] = [
    (
        r"\bgit\s+push\s+(?:.*\s)?(?:-f|--force|--force-with-lease)\b.*\b(main|master|production|prod|develop|deploy)\b",
        "git push --force on protected branch",
        "Add `# CONFIRMED-FORCE-PUSH` to the command, OR work on a feature branch.",
    ),
    (
        r"\bfirebase\s+(?:deploy|firestore:delete|database:remove)\b.*--project[= ](?:.*?)(?:prod|production)",
        "firebase destructive op against prod project",
        "Add `# CONFIRMED-PROD-DEPLOY` to the command after manual review.",
    ),
    (
        r"\bgcloud\s+(?:.*\s)?(?:projects\s+delete|sql\s+databases\s+delete|storage\s+rm\s+-r)",
        "gcloud destructive operation",
        "Add `# CONFIRMED-GCLOUD-DESTRUCTIVE` to the command line.",
    ),
    (
        r"\bnpm\s+(?:publish|unpublish)\b",
        "npm publish/unpublish",
        "Add `# CONFIRMED-NPM-PUBLISH` if intentional.",
    ),
    (
        r"\bpub\s+publish\b",
        "dart pub publish",
        "Add `# CONFIRMED-PUB-PUBLISH` if intentional.",
    ),
    (
        r"\bgit\s+reset\s+(?:.*\s)?--hard\b",
        "git reset --hard (drops uncommitted work)",
        "Add `# CONFIRMED-RESET-HARD` if you really want to discard local changes.",
    ),
    (
        r"\bflutter\s+clean\b",
        "flutter clean (forbidden auto-run per personal-operating-mode rule)",
        "Add `# CONFIRMED-FLUTTER-CLEAN` if you intentionally wipe build cache.",
    ),
    (
        r"\b(?:npm\s+(?:install|i)|yarn\s+add|pnpm\s+(?:add|install))\s+(?:-[^\s]*\s+)*[a-zA-Z@][^\s]*",
        "npm/yarn/pnpm install <package> (adds new dependency)",
        "Add `# CONFIRMED-ADD-DEP` after deciding on the package + version.",
    ),
    (
        r"\b(?:flutter\s+pub\s+add|dart\s+pub\s+add)\s+[a-zA-Z][^\s]*",
        "flutter/dart pub add <package> (adds new dependency)",
        "Add `# CONFIRMED-ADD-DEP` after deciding on the package + version.",
    ),
    (
        r"\bfirebase\s+auth:(?:export|import)\b",
        "firebase auth:export/import (PII bulk read/write)",
        "Add `# CONFIRMED-AUTH-PII` after manual security review.",
    ),
]

CONFIRM_TOKEN_RE = re.compile(
    r"#\s*CONFIRMED-(?:FORCE-PUSH|PROD-DEPLOY|GCLOUD-DESTRUCTIVE|NPM-PUBLISH|PUB-PUBLISH"
    r"|RESET-HARD|FLUTTER-CLEAN|ADD-DEP|AUTH-PII)\b"
)


def deny(reason: str) -> int:
    """Return JSON deny + exit 2 (Cursor blocks the action)."""
    out = {"permission": "deny", "user_message": reason, "agent_message": reason}
    print(json.dumps(out))
    return 2


def allow() -> int:
    """Allow the action."""
    print(json.dumps({"permission": "allow"}))
    return 0


def main() -> int:
    try:
        raw = sys.stdin.read()
        data = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError as exc:
        print(f"[hook:block_dangerous_commands] could not parse stdin: {exc}", file=sys.stderr)
        return 0  # fail-open

    # Cursor's beforeShellExecution payload shape
    cmd = data.get("command", "") or ""
    if not cmd.strip():
        return 0

    cmd_norm = cmd.strip()

    for pattern, label in HARD_BLOCK_PATTERNS:
        if re.search(pattern, cmd_norm, flags=re.IGNORECASE):
            return deny(
                f"BLOCKED — matches hard-block rule '{label}'.\n"
                f"Command: {cmd_norm}\n"
                f"This pattern is never auto-runnable. Run manually if intentional."
            )

    has_confirm = bool(CONFIRM_TOKEN_RE.search(cmd_norm))
    for pattern, label, hint in CONFIRMED_PATTERNS:
        if re.search(pattern, cmd_norm, flags=re.IGNORECASE) and not has_confirm:
            return deny(
                f"BLOCKED — matches '{label}'.\n"
                f"Command: {cmd_norm}\n"
                f"Hint: {hint}\n"
                f"Or run it manually in your own terminal."
            )

    return allow()


if __name__ == "__main__":
    sys.exit(main())
