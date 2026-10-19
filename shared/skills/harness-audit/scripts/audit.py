#!/usr/bin/env python3
"""Bounded, read-only harness inventory and Codex cumulative usage reporting."""
import argparse
import hashlib
import json
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path
from urllib.parse import unquote

try:
    import tomllib
except ImportError:
    tomllib = None


def frontmatter(text):
    """Parse only the name/description subset; the stock validator owns YAML validity."""
    if not text.startswith("---\n"):
        return {}, text
    parts = text.split("\n---", 1)
    if len(parts) != 2:
        return {}, text
    result = {}
    lines = parts[0].splitlines()[1:]
    for index, line in enumerate(lines):
        match = re.match(r"^(name|description):\s*(.*)$", line)
        if not match:
            continue
        key, value = match.groups()
        if value.startswith((">", "|")):
            block = []
            for following in lines[index + 1:]:
                if following and not following[0].isspace():
                    break
                block.append(following.strip())
            value = " ".join(block).strip()
        elif value.startswith('"'):
            try:
                value = json.loads(value)
            except json.JSONDecodeError:
                value = value.strip('"')
        elif value.startswith("'"):
            value = value.strip("'").replace("''", "'")
        result[key] = value
    return result, parts[1].lstrip("\n")


def config_for(home, config_path, notes):
    path = config_path or home / ".codex/config.toml"
    if not path.exists():
        return {}
    if tomllib is None:
        # macOS ships Python 3.9. Read only the documented simple discovery fields;
        # never reinterpret arbitrary config as JSON or expose its other values.
        config = {"skills": {"config": []}, "plugins": {}}
        current = None
        for line in path.read_text().splitlines():
            line = line.strip()
            if line.startswith("["):
                current = None
                if line == "[[skills.config]]":
                    current = {}
                    config["skills"]["config"].append(current)
                else:
                    section = re.fullmatch(r'\[plugins\.("(?:[^"\\]|\\.)*"|\'[^\']*\')\]', line)
                    if section:
                        value = section.group(1)
                        name = json.loads(value) if value.startswith('"') else value[1:-1]
                        current = config["plugins"].setdefault(name, {})
                continue
            if current is not None and line and not line.startswith("#"):
                field = re.fullmatch(r'(path|enabled)\s*=\s*("(?:[^"\\]|\\.)*"|\'[^\']*\'|true|false)\s*(?:#.*)?', line)
                if field:
                    key, value = field.groups()
                    current[key] = value == "true" if value in ("true", "false") else json.loads(value) if value.startswith('"') else value[1:-1]
                elif re.match(r"(?:path|enabled)\s*=", line):
                    notes.append("Unsupported discovery config value: enable/disable state may be incomplete; use Python 3.11+.")
        return config
    try:
        return tomllib.loads(path.read_text())
    except (OSError, ValueError) as error:
        notes.append(f"Cannot parse config {path}: {type(error).__name__}")
        return {}


def local_path(value, base, home):
    value = unquote(value.strip("<>"))
    value = value.replace("$HOME/", str(home) + "/", 1)
    if value.startswith("~/"):
        return home / value[2:]
    path = Path(value)
    return path if path.is_absolute() else base / path


def check_links(path, text, home):
    # Code examples are not references or executable @ imports.
    clean = re.sub(r"```.*?```|~~~.*?~~~", "", text, flags=re.S)
    clean = re.sub(r"`[^`\n]+`", "", clean)
    targets = re.findall(r"\[[^\]]*\]\((<[^>]+>|[^\s)]+)(?:\s+[^)]*)?\)", clean)
    targets += re.findall(r"(?<!\w)@((?:~/|\$HOME/|/|\.\.?/)[^\s`]+)", clean)
    problems = []
    for value in targets:
        value = value.rstrip(".,;")
        if value.startswith("#") or re.match(r"[a-zA-Z][\w+.-]*:", value):
            continue
        # A source code line fragment is not part of a filesystem path.
        value = re.sub(r":\d+(?:-\d+)?$", "", value.split("#", 1)[0])
        if not value:
            continue
        target = local_path(value, path.parent, home)
        if not target.exists():
            problems.append({"file": str(path), "target": str(target), "kind": "missing_reference"})
    return problems


def inventory(args):
    root, home = args.root.resolve(), args.home.resolve()
    notes = []
    config = config_for(home, args.codex_config, notes)
    disabled = {local_path(item["path"], home, home).resolve()
                for item in config.get("skills", {}).get("config", [])
                if item.get("enabled") is False and isinstance(item.get("path"), str)}
    discovery = args.discovery_dir or [home / ".agents/skills", home / ".codex/skills"]
    cache = home / ".codex/plugins/cache"
    plugin_states = {}
    if args.include_plugin_cache and cache.is_dir():
        for skills in sorted(cache.glob("*/*/*/skills")):
            market, name = skills.relative_to(cache).parts[:2]
            keys = [f"{name}@{market}", f"{name}@{market.removesuffix('-remote')}"]
            states = [config.get("plugins", {}).get(key, {}).get("enabled") for key in keys]
            plugin_states[str(skills)] = False if False in states and True not in states else True if True in states else None
            discovery.append(skills)
        notes.append("Plugin cache entries are candidates; versions/authentication/live tool availability are not verified.")
    encoder = None
    try:
        import tiktoken
        encoder = tiktoken.get_encoding(args.encoding)
    except (ImportError, ValueError):
        notes.append("tiktoken unavailable/encoding unknown: token counts omitted, no character-to-token estimate.")

    def size(text):
        result = {"chars": len(text), "bytes": len(text.encode())}
        if encoder:
            result["tokens"] = len(encoder.encode(text, disallowed_special=()))
        return result

    records, problems, files = [], [], set()
    for directory in discovery:
        directory = directory.absolute()
        if not directory.is_dir():
            continue
        for child in sorted(directory.iterdir()):
            if child.is_symlink() and not child.exists():
                problems.append({"file": str(child), "kind": "broken_symlink"})
                continue
            entry = child / "SKILL.md"
            if not entry.is_file():
                continue
            if len(records) >= args.max_files:
                notes.append("Discovery limit reached; results are partial.")
                break
            if entry.stat().st_size > args.max_file_bytes:
                problems.append({"file": str(entry), "kind": "file_too_large"})
                continue
            text = entry.read_text(errors="replace")
            meta, body = frontmatter(text)
            plugin_state = plugin_states.get(str(directory))
            is_disabled = entry.resolve() in disabled or plugin_state is False
            records.append({"name": meta.get("name", child.name), "path": str(entry),
                            "resolved_path": str(entry.resolve()), "disabled": is_disabled,
                            "plugin_cache_candidate": str(directory) in plugin_states,
                            "hash": hashlib.sha256(text.encode()).hexdigest(),
                            "description": size(meta.get("description", "")), "body": size(body)})
    for area in ("shared", "codex", "claude", "gemini", "omp", "pi"):
        directory = root / area
        if not directory.is_dir():
            continue
        for path in directory.rglob("*"):
            if path.is_symlink() and not path.exists():
                problems.append({"file": str(path), "kind": "broken_symlink"})
            if path.suffix == ".md" and path.is_file():
                files.add(path)
    for record in records:
        files.add(Path(record["path"]))
    measures = []
    for path in sorted(files)[:args.max_files]:
        if path.stat().st_size > args.max_file_bytes:
            problems.append({"file": str(path), "kind": "file_too_large"})
            continue
        text = path.read_text(errors="replace")
        problems.extend(check_links(path, text, home))
        measures.append({"path": str(path), **size(text)})
    if len(files) > args.max_files:
        notes.append(f"Inventory bounded to {args.max_files} of {len(files)} Markdown files.")
    groups, cache_groups = defaultdict(list), defaultdict(list)
    for record in records:
        if not record["disabled"]:
            selected_groups = cache_groups if record["plugin_cache_candidate"] else groups
            selected_groups[record["name"]].append(record)
    duplicates = [{"name": name, "paths": [item["path"] for item in items],
                   "content_drift": len({item["hash"] for item in items}) > 1}
                  for name, items in sorted(groups.items()) if len(items) > 1]
    cache_duplicates = [{"name": name, "paths": [item["path"] for item in items],
                         "content_drift": len({item["hash"] for item in items}) > 1}
                        for name, items in sorted(cache_groups.items()) if len(items) > 1]
    validators = []
    if args.validator:
        for path in sorted((root / "shared/skills").glob("*/SKILL.md"))[:args.max_files]:
            try:
                process = subprocess.run([sys.executable, str(args.validator), str(path.parent)],
                                         capture_output=True, text=True, timeout=30)
                validators.append({"skill": path.parent.name, "exit_code": process.returncode,
                                   "message": (process.stdout + process.stderr).strip()[:1000]})
            except (OSError, subprocess.TimeoutExpired) as error:
                validators.append({"skill": path.parent.name, "error": type(error).__name__})
    totals = {key: sum(item.get(key, 0) for item in measures) for key in ("chars", "bytes")}
    if encoder:
        totals["tokens"] = sum(item["tokens"] for item in measures)
    return {"mode": "inventory", "root": str(root), "home": str(home),
            "encoding": args.encoding if encoder else None, "inventory_totals": totals,
            "inventory_file_count": len(measures), "largest_files": sorted(measures, key=lambda item: item["chars"], reverse=True)[:20],
            "discovery": records, "active_duplicate_names": duplicates,
            "plugin_cache_duplicate_candidates": cache_duplicates,
            "reference_problems": problems, "validation": validators, "notes": notes}


def usage(args):
    directories = args.session_dir or [args.home / ".codex/sessions"]
    files = {path for directory in directories if directory.is_dir() for path in directory.rglob("*.jsonl")}
    selected = sorted(files, key=lambda path: path.stat().st_mtime, reverse=True)[:args.max_logs]
    result = []
    for path in selected:
        latest, session_id = None, None
        invalid = 0
        with path.open(errors="replace") as stream:
            for line in stream:
                try:
                    event = json.loads(line)
                except json.JSONDecodeError:
                    invalid += 1
                    continue
                payload = event.get("payload") or {}
                if not isinstance(payload, dict):
                    continue
                if event.get("type") == "session_meta":
                    session_id = payload.get("id")
                if event.get("type") != "event_msg" or payload.get("type") != "token_count":
                    continue
                info = payload.get("info") or {}
                cumulative = info.get("total_token_usage") if isinstance(info, dict) else None
                if isinstance(cumulative, dict):
                    allowed = ("input_tokens", "cached_input_tokens", "output_tokens", "reasoning_output_tokens", "total_tokens")
                    latest = {key: cumulative[key] for key in allowed
                              if isinstance(cumulative.get(key), (int, float)) and not isinstance(cumulative[key], bool)}
        record = {"path": str(path), "session_id": session_id, "cumulative_usage": latest,
                  "invalid_json_lines": invalid}
        if latest and "input_tokens" in latest and "cached_input_tokens" in latest:
            record["uncached_input_tokens"] = latest["input_tokens"] - latest["cached_input_tokens"]
        result.append(record)
    return {"mode": "usage", "logs_examined": len(selected), "logs_available": len(files),
            "sessions": result, "notes": ["Last recorded cumulative total per log, never a sum of token_count events.",
            "No cross-session sum: forks/resumed logs can overlap. Null means cumulative usage unavailable.",
            "Cached input is included in input_tokens; reasoning output is included in output_tokens.",
            "Only Codex cumulative token_count schema is supported; no user/assistant text or prices are emitted."]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[4])
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument("--discovery-dir", action="append", type=Path)
    parser.add_argument("--codex-config", type=Path)
    parser.add_argument("--include-plugin-cache", action="store_true")
    parser.add_argument("--validator", type=Path)
    parser.add_argument("--encoding", default="o200k_base")
    parser.add_argument("--max-files", type=int, default=1000)
    parser.add_argument("--max-file-bytes", type=int, default=262144)
    parser.add_argument("--usage", action="store_true")
    parser.add_argument("--session-dir", action="append", type=Path)
    parser.add_argument("--max-logs", type=int, default=20)
    args = parser.parse_args()
    if min(args.max_files, args.max_file_bytes, args.max_logs) < 1:
        parser.error("Limits must be positive")
    print(json.dumps(usage(args) if args.usage else inventory(args), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
