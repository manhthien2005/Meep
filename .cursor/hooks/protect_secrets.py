#!/usr/bin/env python3
"""
Protect secret/credential files from Cursor agent read or modification.

Listens on Cursor's `beforeReadFile` and `afterFileEdit` hooks. Reads JSON
from stdin, returns JSON to stdout. Exit 2 = block (deny).

Why beforeReadFile too: even reading a service-account JSON pulls secrets
into the model context, where they may end up in a future response or memory.

`.env.example` and similar template files are explicitly allowlisted.

Mirrors `.windsurf/hooks/protect_secrets.py` behavior.
"""

from __future__ import annotations

import json
import re
import sys

# ---- Filename patterns considered secrets ---------------------------------
SECRET_FILE_PATTERNS: list[tuple[str, str]] = [
    (r"(^|[\\/])\.env(\.[^\\/]+)?$", ".env file"),
    (r"(^|[\\/])\.envrc$", ".envrc (direnv)"),
    (r"\.pem$", "PEM private key"),
    (r"\.key$", "raw key file"),
    (r"\.p12$", "PKCS#12 keystore"),
    (r"\.pfx$", "PFX keystore"),
    (r"\.keystore$", "Java keystore"),
    (r"\.jks$", "Java keystore"),
    (r"(^|[\\/])key\.properties$", "Android signing config"),
    (r"firebase-adminsdk[^\\/]*\.json$", "Firebase Admin SDK service account"),
    (r"(^|[\\/])serviceAccount[^\\/]*\.json$", "service account JSON"),
    (r"(^|[\\/])google-services\.json$", "Android google-services.json"),
    (r"(^|[\\/])GoogleService-Info\.plist$", "iOS GoogleService-Info.plist"),
    (r"(^|[\\/])\.npmrc$", ".npmrc (may contain auth tokens)"),
    (r"(^|[\\/])id_rsa$|id_ed25519$|id_ecdsa$", "SSH private key"),
    (r"\.ovpn$", "OpenVPN config"),
    (r"\.kubeconfig$|(^|[\\/])kubeconfig$", "Kubernetes config"),
    (r"(^|[\\/])credentials(\.[^\\/]+)?$", "credentials file"),
]

# ---- Allowlist (templates, examples, documentation) ----------------------
ALLOWLIST_PATTERNS: list[str] = [
    r"\.env\.example$",
    r"\.env\.sample$",
    r"\.env\.template$",
    r"\.envrc\.example$",
    r"firebase-adminsdk[^\\/]*\.example\.json$",
    r"google-services\.example\.json$",
]


def normalize_path(path: str) -> str:
    return path.replace("\\", "/").lower()


def is_allowlisted(path: str) -> bool:
    norm = normalize_path(path)
    return any(re.search(p, norm) for p in ALLOWLIST_PATTERNS)


def match_secret(path: str) -> str | None:
    if not path:
        return None
    norm = normalize_path(path)
    for pattern, label in SECRET_FILE_PATTERNS:
        if re.search(pattern, norm):
            return label
    return None


def deny(reason: str) -> int:
    print(json.dumps({"permission": "deny", "user_message": reason, "agent_message": reason}))
    return 2


def allow() -> int:
    print(json.dumps({"permission": "allow"}))
    return 0


def main() -> int:
    try:
        raw = sys.stdin.read()
        data = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError as exc:
        print(f"[hook:protect_secrets] could not parse stdin: {exc}", file=sys.stderr)
        return 0

    # Cursor payload: file_path / filePath depending on hook
    file_path = data.get("file_path") or data.get("filePath") or data.get("path") or ""
    if not file_path:
        return 0

    if is_allowlisted(file_path):
        return allow()

    label = match_secret(file_path)
    if label is None:
        return allow()

    return deny(
        f"BLOCKED — refusing to access '{file_path}'.\n"
        f"Reason: file matches '{label}' pattern and may contain credentials.\n"
        f"If you genuinely need this file inspected, ask the user to share "
        f"the relevant content manually, or rename the file to a non-secret path."
    )


if __name__ == "__main__":
    sys.exit(main())
