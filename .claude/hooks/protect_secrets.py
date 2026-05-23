#!/usr/bin/env python3
"""
Protect secret/credential files from Claude Code agent read or modification.
Listens on PreToolUse (Read) and PostToolUse (Edit/Write). Reads JSON from
stdin, prints plain-text reason to stdout, exits 2 to block or 0 to allow.
"""

from __future__ import annotations

import json
import re
import sys

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
    (r"(^|[\\/])\.npmrc$", ".npmrc (có thể chứa auth tokens)"),
    (r"(^|[\\/])id_rsa$|id_ed25519$|id_ecdsa$", "SSH private key"),
    (r"\.ovpn$", "OpenVPN config"),
    (r"(^|[\\/])credentials(\.[^\\/]+)?$", "credentials file"),
]

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


def extract_path(data: dict) -> str:
    # Claude Code Read tool: {"file_path": "..."}
    # Claude Code Edit tool: {"file_path": "...", ...}
    # Claude Code Write tool: {"file_path": "...", ...}
    return (
        data.get("file_path")
        or data.get("filePath")
        or data.get("path")
        or data.get("tool_input", {}).get("file_path")
        or ""
    )


def main() -> int:
    try:
        raw = sys.stdin.read()
        data = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        return 0  # fail-open

    file_path = extract_path(data)
    if not file_path:
        return 0

    if is_allowlisted(file_path):
        return 0

    label = match_secret(file_path)
    if label is None:
        return 0

    print(
        f"CHẶN — từ chối truy cập '{file_path}'\n"
        f"Lý do: file khớp pattern '{label}' và có thể chứa credentials.\n"
        f"Nếu anh thực sự cần inspect file này, hãy paste nội dung liên quan thủ công vào chat."
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
