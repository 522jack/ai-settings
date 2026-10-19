#!/usr/bin/env bash
set -e

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_HOME="$HOME"
SKILLS_ONLY=false
ADOPT_LEGACY=false
while [ "$#" -gt 0 ]; do
    case "$1" in
        --root|--home)
            [ "$#" -ge 2 ] && [ -n "$2" ] || { echo "$1 requires a directory" >&2; exit 2; }
            if [ "$1" = --root ]; then REPO="$2"; else TARGET_HOME="$2"; fi
            shift 2 ;;
        --skills-only) SKILLS_ONLY=true; shift ;;
        --adopt-legacy) ADOPT_LEGACY=true; shift ;;
        *) echo "Usage: $0 [--root DIR] [--home DIR] [--skills-only] [--adopt-legacy]" >&2; exit 2 ;;
    esac
done
REPO="$(cd "$REPO" && pwd -P)"
TARGET_HOME="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve())' "$TARGET_HOME")"
BACKUP="$TARGET_HOME/.local/state/ai-harness/backups/$(date +%Y%m%d_%H%M%S)_$$"
install_skills() {
    local adoption=()
    [ "$ADOPT_LEGACY" = true ] && adoption=(--adopt-legacy)
    python3 "$REPO/shared/scripts/install-shared-skills.py" --root "$REPO" --home "$TARGET_HOME" \
        --backup-dir "$BACKUP" "${adoption[@]}"
}
if [ "$SKILLS_ONLY" = true ]; then
    install_skills
    exit
fi

echo "Setting up AI agent configs from $REPO"

# Backup existing files before symlinking
backup_if_exists() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mkdir -p "$BACKUP"
        cp -r "$target" "$BACKUP/"
        echo "  Backed up: $target → $BACKUP/"
    fi
}

# Claude Code
mkdir -p "$TARGET_HOME/.claude"

backup_if_exists "$TARGET_HOME/.claude/CLAUDE.md"
backup_if_exists "$TARGET_HOME/.claude/settings.json"
backup_if_exists "$TARGET_HOME/.claude/hooks"
# BSD ln follows a destination symlink to a directory, creating a nested self-link.
[ -L "$TARGET_HOME/.claude/hooks" ] && rm "$TARGET_HOME/.claude/hooks"
# Remove dir before symlinking (ln -sf won't replace an existing dir)
[ -d "$TARGET_HOME/.claude/hooks" ] && [ ! -L "$TARGET_HOME/.claude/hooks" ] && rm -rf "$TARGET_HOME/.claude/hooks"

ln -sf "$REPO/claude/CLAUDE.md"     "$TARGET_HOME/.claude/CLAUDE.md"
ln -sf "$REPO/claude/settings.json" "$TARGET_HOME/.claude/settings.json"
ln -sf "$REPO/claude/hooks"         "$TARGET_HOME/.claude/hooks"

echo "  Claude Code: ~/.claude/CLAUDE.md → $REPO/claude/CLAUDE.md"
echo "  Claude Code: ~/.claude/settings.json → $REPO/claude/settings.json"
echo "  Claude Code: ~/.claude/hooks → $REPO/claude/hooks"

# Agents (symlink each agent file individually)
mkdir -p "$TARGET_HOME/.claude/agents"

for agent_file in "$REPO/shared/agents"/*.md; do
    agent_name="$(basename "$agent_file")"
    target="$TARGET_HOME/.claude/agents/$agent_name"
    [ -f "$target" ] && [ ! -L "$target" ] && { mkdir -p "$BACKUP"; cp "$target" "$BACKUP/"; rm "$target"; }
    ln -sf "$agent_file" "$target"
done

# Agent references (symlink whole dir if possible, else individual files)
[ -L "$TARGET_HOME/.claude/agent-references" ] && rm "$TARGET_HOME/.claude/agent-references"
if [ ! -e "$TARGET_HOME/.claude/agent-references" ]; then
    ln -sf "$REPO/shared/agent-references" "$TARGET_HOME/.claude/agent-references"
else
    mkdir -p "$TARGET_HOME/.claude/agent-references"
    for ref_file in "$REPO/shared/agent-references"/*.md; do
        ref_name="$(basename "$ref_file")"
        ln -sf "$ref_file" "$TARGET_HOME/.claude/agent-references/$ref_name"
    done
fi

echo "  Agents: ~/.claude/agents/* → $REPO/shared/agents/*"
echo "  Agent references: ~/.claude/agent-references → $REPO/shared/agent-references"

# One physical discovery location shared by Codex and Gemini; custom skills are preserved.
# Existing installations migrate with --adopt-legacy, with backups outside the source repo.
install_skills

# Codex
mkdir -p "$TARGET_HOME/.codex"

backup_if_exists "$TARGET_HOME/.codex/AGENTS.md"

ln -sf "$REPO/shared/AGENTS.md" "$TARGET_HOME/.codex/AGENTS.md"

echo "  Codex: ~/.codex/AGENTS.md → $REPO/shared/AGENTS.md"

# Oh My Pi
mkdir -p "$TARGET_HOME/.omp/agent"

backup_if_exists "$TARGET_HOME/.omp/agent/AGENTS.md"

ln -sf "$REPO/omp/AGENTS.md" "$TARGET_HOME/.omp/agent/AGENTS.md"

echo "  Oh My Pi: ~/.omp/agent/AGENTS.md → $REPO/omp/AGENTS.md"

# Global neutral AGENTS.md
# Harness-specific adapters must be installed in their own runtime locations.
if [ -L "$TARGET_HOME/AGENTS.md" ]; then
    echo "  Global: preserving existing ~/AGENTS.md symlink"
else
    backup_if_exists "$TARGET_HOME/AGENTS.md"
    printf '%s\n' "@${REPO}/shared/global-neutral.md" > "$TARGET_HOME/AGENTS.md"
    echo "  Global: ~/AGENTS.md → imports $REPO/shared/global-neutral.md"
fi

# Pi
mkdir -p "$TARGET_HOME/.pi/agent" "$TARGET_HOME/.pi/agent/extensions"
backup_if_exists "$TARGET_HOME/.pi/agent/AGENTS.md"
ln -sf "$REPO/pi/AGENTS.md" "$TARGET_HOME/.pi/agent/AGENTS.md"
for extension_file in "$REPO/pi/extensions"/*.ts; do
    [ -e "$extension_file" ] || continue
    extension_name="$(basename "$extension_file")"
    target="$TARGET_HOME/.pi/agent/extensions/$extension_name"
    [ -L "$target" ] && rm "$target"
    [ -e "$target" ] && [ ! -L "$target" ] && { mkdir -p "$BACKUP"; cp -r "$target" "$BACKUP/"; rm -rf "$target"; }
    ln -sf "$extension_file" "$target"
done
echo "  Pi: ~/.pi/agent/AGENTS.md → $REPO/pi/AGENTS.md"
echo "  Pi extensions: ~/.pi/agent/extensions/* → $REPO/pi/extensions/*"

# Gemini in Android Studio
# Android Studio scans AGENTS.md from the active file up through its parent directories.
# Keep ~/AGENTS.md neutral; add/import $REPO/gemini/AGENTS.md only in Gemini-specific configuration
# or in a project-local AGENTS.md when Gemini needs its adapter.
echo "  Gemini: adapter remains at $REPO/gemini/AGENTS.md"


# csync alias hint
echo ""
echo "Add to ~/.zshrc or ~/.bashrc:"
echo "  alias csync='cd \$HOME/dotfiles/ai && git add -A && git commit -m \"sync: \$(hostname) \$(date +%Y-%m-%d)\" && git push && cd -'"
echo ""
echo "Done."
