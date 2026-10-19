#!/usr/bin/env python3
"""Install one maintained physical skill copy for Codex/Gemini, preserving custom files."""
import argparse
import hashlib
import json
import shutil
import tempfile
from datetime import datetime, timezone
from pathlib import Path


IGNORED = {".DS_Store", "__pycache__", ".git"}


def tree_hash(directory):
    digest = hashlib.sha256()
    for path in sorted(directory.rglob("*")):
        relative = path.relative_to(directory)
        if any(part in IGNORED for part in relative.parts):
            continue
        digest.update(str(relative).encode())
        if path.is_symlink():
            digest.update(b"link:" + str(path.readlink()).encode())
        elif path.is_file():
            digest.update(b"file:" + path.read_bytes())
        elif path.is_dir():
            digest.update(b"directory")
    return digest.hexdigest()


def managed_link(path, source):
    return path.is_symlink() and path.resolve() == source.resolve()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument("--backup-dir", type=Path)
    parser.add_argument("--adopt-legacy", action="store_true",
                        help="Adopt prior setup copies only when a matching managed Codex link exists.")
    args = parser.parse_args()
    root, home = args.root.resolve(), args.home.resolve()
    sources = root / "shared/skills"
    if not sources.is_dir():
        parser.error(f"Missing skill sources: {sources}")
    state_dir = home / ".local/state/ai-harness"
    state_path = state_dir / "skills.json"
    state = json.loads(state_path.read_text()) if state_path.exists() else {}
    backup = args.backup_dir or state_dir / "backups" / datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    result = {"installed": [], "unchanged": [], "removed_redundant_links": [], "preserved_conflicts": []}
    for source in sorted(sources.iterdir()):
        if not (source / "SKILL.md").is_file():
            continue
        name = source.name
        target = home / ".agents/skills" / name
        codex = home / ".codex/skills" / name
        runtime_links = [home / runtime / "skills" / name for runtime in (".claude", ".omp/agent")]
        owned = state.get(name)
        target_present = target.exists() or target.is_symlink()
        legacy = args.adopt_legacy and managed_link(codex, source) and target.is_dir() and not target.is_symlink()
        expected = tree_hash(source)
        current = tree_hash(target) if target.is_dir() and not target.is_symlink() else None
        owned_intact = owned and owned.get("hash") == current
        conflicts = []
        if target_present and not (owned_intact or legacy or managed_link(target, source)):
            conflicts.append(str(target))
        # Preflight every discovery path before installing or claiming this skill.
        for link in (codex, *runtime_links):
            if (link.exists() or link.is_symlink()) and not managed_link(link, source):
                conflicts.append(str(link))
        if conflicts:
            result["preserved_conflicts"].extend(conflicts)
            continue
        if current != expected or target.is_symlink():
            target.parent.mkdir(parents=True, exist_ok=True)
            with tempfile.TemporaryDirectory(prefix=".harness-install-", dir=target.parent) as staging:
                staged = Path(staging) / name
                shutil.copytree(source, staged, symlinks=True,
                                ignore=shutil.ignore_patterns(*IGNORED))
                if target_present:
                    saved = backup / ".agents/skills" / name
                    saved.parent.mkdir(parents=True, exist_ok=True)
                    if target.is_symlink():
                        saved.symlink_to(target.readlink())
                        target.unlink()
                    else:
                        shutil.copytree(target, saved, symlinks=True)
                        shutil.rmtree(target)
                staged.rename(target)
            result["installed"].append(name)
        else:
            result["unchanged"].append(name)
        state[name] = {"source": str(source), "hash": expected}
        # Only remove links that point to this harness source. Custom Codex skills survive.
        if managed_link(codex, source):
            codex.unlink()
            result["removed_redundant_links"].append(str(codex))
        for link in runtime_links:
            if managed_link(link, source):
                continue
            link.parent.mkdir(parents=True, exist_ok=True)
            link.symlink_to(source, target_is_directory=True)
    encoded = json.dumps(state, indent=2, ensure_ascii=False) + "\n"
    if not state_path.exists() or state_path.read_text() != encoded:
        state_dir.mkdir(parents=True, exist_ok=True)
        temporary = state_path.with_suffix(".tmp")
        temporary.write_text(encoded)
        temporary.replace(state_path)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 1 if result["preserved_conflicts"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
