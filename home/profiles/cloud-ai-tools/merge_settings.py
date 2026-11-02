import argparse
import json
import os
import tempfile
from collections.abc import MutableMapping
from pathlib import Path

import tomlkit
from tomlkit.exceptions import ParseError


def reject_json_constant(value):
    raise ValueError(f"Invalid JSON constant: {value}")


def merge_json(existing, declared):
    for key, value in declared.items():
        if isinstance(value, dict) and isinstance(existing.get(key), dict):
            merge_json(existing[key], value)
        else:
            existing[key] = value


def write_atomic(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=path.parent,
            prefix=f".{path.name}.",
            delete=False,
        ) as temporary:
            temporary_path = Path(temporary.name)
            os.fchmod(temporary.fileno(), 0o600)
            temporary.write(content)
            temporary.flush()
            os.fsync(temporary.fileno())
        os.replace(temporary_path, path)
        temporary_path = None
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)


def merge_settings(kind, path, declared):
    try:
        content = path.read_text(encoding="utf-8")
    except FileNotFoundError:
        if path.is_symlink():
            raise
        content = ""

    if kind == "codex":
        doc = tomlkit.parse(content)
        servers = doc.setdefault("mcp_servers", tomlkit.table())
        if not isinstance(servers, MutableMapping):
            raise ValueError("mcp_servers must be a TOML table")
        for name, server in declared.items():
            table = servers.setdefault(name, tomlkit.table())
            if not isinstance(table, MutableMapping):
                raise ValueError(f"mcp_servers.{name} must be a TOML table")
            for key in ("command", "args", "env"):
                if key in server and server[key]:
                    table[key] = server[key]
        result = tomlkit.dumps(doc)
    else:
        doc = (
            json.loads(content, parse_constant=reject_json_constant)
            if content.strip()
            else {}
        )
        if not isinstance(doc, dict):
            raise ValueError("settings must be a JSON object")
        merge_json(doc, declared)
        result = json.dumps(doc, indent=2, ensure_ascii=False, allow_nan=False) + "\n"

    write_atomic(path, result)


def main():
    parser = argparse.ArgumentParser(description="Merge declared AI CLI settings safely")
    parser.add_argument("kind", choices=("codex", "antigravity"))
    parser.add_argument("path", type=Path)
    parser.add_argument("declared", type=json.loads)
    args = parser.parse_args()
    try:
        merge_settings(args.kind, args.path, args.declared)
    except (OSError, UnicodeError, ValueError, ParseError) as error:
        parser.exit(
            1,
            f"Cannot merge settings in {args.path}: {error}\n"
            "Existing configuration was not replaced.\n",
        )


if __name__ == "__main__":
    main()
