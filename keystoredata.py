#!/usr/bin/env python3
"""Generate secure Android keystore handoff data.

Prompts for a project name, fills fixed DN defaults, generates a 32-character
password, and writes a JSON handoff file for later keystore creation.
Does not create the .jks / .keystore itself.
"""

from __future__ import annotations

import json
import re
import secrets
import string
from datetime import datetime, timezone
from pathlib import Path

PASSWORD_LENGTH = 32
# Shell / keytool-friendly alphabet (no quotes, backticks, $, \, spaces)
PASSWORD_ALPHABET = string.ascii_letters + string.digits + "!@#%^*_+-="

DEFAULT_CN = "Shawn McPeek"
DEFAULT_O = "Daddoo Dev"
DEFAULT_L = "Firestone"
DEFAULT_ST = "CO"
DEFAULT_C = "US"

OUTPUT_DIR = Path(__file__).resolve().parent / "secrets"
GITIGNORE_PATH = Path(__file__).resolve().parent / ".gitignore"
GITIGNORE_ENTRIES = (
    "secrets/",
    "keystore-data/",
    "*-keystore-data.json",
    ".env",
    "*.jks",
    "*.keystore",
    "android/key.properties",
)

AGENT_INSTRUCTIONS = [
    "This file contains secrets. Never commit it.",
    "Before generating the keystore, ensure .gitignore covers: this handoff file, "
    ".env, *.jks, *.keystore, and any keystore-data/ folder.",
    "Keep the release keystore and signing.env under secrets/ (gitignored). "
    "android/key.properties may stay under android/ with storeFile=../secrets/<keystore>.",
    "Use the fields in this file with keytool to create the release keystore. "
    "Do not regenerate the password — use store_password / key_password as written.",
    "Store password and key password are the same by default.",
]


def slugify(name: str) -> str:
    slug = name.strip().lower()
    slug = re.sub(r"[^a-z0-9]+", "-", slug)
    return slug.strip("-") or "project"


def generate_password(length: int = PASSWORD_LENGTH) -> str:
    return "".join(secrets.choice(PASSWORD_ALPHABET) for _ in range(length))


def ensure_gitignore() -> None:
    existing = ""
    if GITIGNORE_PATH.exists():
        existing = GITIGNORE_PATH.read_text(encoding="utf-8")

    lines = existing.splitlines()
    missing = [entry for entry in GITIGNORE_ENTRIES if entry not in lines]
    if not missing:
        return

    block = "\n".join(missing)
    if existing and not existing.endswith("\n"):
        existing += "\n"
    if existing and not existing.endswith("\n\n"):
        existing += "\n"
    GITIGNORE_PATH.write_text(
        existing + "# Keystore handoff secrets\n" + block + "\n",
        encoding="utf-8",
    )


def prompt_project_name() -> str:
    while True:
        name = input("Project name: ").strip()
        if name:
            return name
        print("Project name is required.")


def build_payload(project_name: str, password: str) -> dict:
    slug = slugify(project_name)
    alias = project_name.strip()
    return {
        "agent_instructions": AGENT_INSTRUCTIONS,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "project_name": project_name.strip(),
        "project_slug": slug,
        "alias": alias,
        "store_password": password,
        "key_password": password,
        "suggested_keystore_filename": f"{slug}-release.keystore",
        "suggested_env": {
            "KEY_ALIAS": alias,
            "KEYSTORE_PASSWORD": password,
            "KEY_PASSWORD": password,
            "KEYSTORE_PATH": f"secrets/{slug}-release.keystore",
        },
        "distinguished_name": {
            "CN": DEFAULT_CN,
            "OU": project_name.strip(),
            "O": DEFAULT_O,
            "L": DEFAULT_L,
            "ST": DEFAULT_ST,
            "C": DEFAULT_C,
        },
        "keytool_dname": (
            f"CN={DEFAULT_CN}, OU={project_name.strip()}, O={DEFAULT_O}, "
            f"L={DEFAULT_L}, ST={DEFAULT_ST}, C={DEFAULT_C}"
        ),
    }


def main() -> None:
    project_name = prompt_project_name()
    password = generate_password()
    payload = build_payload(project_name, password)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    ensure_gitignore()

    out_path = OUTPUT_DIR / f"{payload['project_slug']}-keystore-data.json"
    out_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    print()
    print(f"Wrote: {out_path}")
    print(f"Alias: {payload['alias']}")
    print(f"Password ({PASSWORD_LENGTH} chars): {password}")
    print("Store + key password are the same.")
    print("Give that JSON file to Cursor to generate secrets/<keystore> + android/key.properties.")


if __name__ == "__main__":
    main()
