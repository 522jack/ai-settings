#!/usr/bin/env bash
set -e

REPO="$HOME/dotfiles/ai"
BACKUP="$HOME/dotfiles/ai/.backup/$(date +%Y%m%d_%H%M%S)"

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
mkdir -p "$HOME/.claude"

backup_if_exists "$HOME/.claude/CLAUDE.md"
backup_if_exists "$HOME/.claude/settings.json"
backup_if_exists "$HOME/.claude/hooks"
# BSD ln follows a destination symlink to a directory, creating a nested self-link.
[ -L "$HOME/.claude/hooks" ] && rm "$HOME/.claude/hooks"
# Remove dir before symlinking (ln -sf won't replace an existing dir)
[ -d "$HOME/.claude/hooks" ] && [ ! -L "$HOME/.claude/hooks" ] && rm -rf "$HOME/.claude/hooks"

ln -sf "$REPO/claude/CLAUDE.md"     "$HOME/.claude/CLAUDE.md"
ln -sf "$REPO/claude/settings.json" "$HOME/.claude/settings.json"
ln -sf "$REPO/claude/hooks"         "$HOME/.claude/hooks"

echo "  Claude Code: ~/.claude/CLAUDE.md → $REPO/claude/CLAUDE.md"
echo "  Claude Code: ~/.claude/settings.json → $REPO/claude/settings.json"
echo "  Claude Code: ~/.claude/hooks → $REPO/claude/hooks"

# Agents (symlink each agent file individually)
mkdir -p "$HOME/.claude/agents"

for agent_file in "$REPO/shared/agents"/*.md; do
    agent_name="$(basename "$agent_file")"
    target="$HOME/.claude/agents/$agent_name"
    [ -f "$target" ] && [ ! -L "$target" ] && { mkdir -p "$BACKUP"; cp "$target" "$BACKUP/"; rm "$target"; }
    ln -sf "$agent_file" "$target"
done

# Agent references (symlink whole dir if possible, else individual files)
[ -L "$HOME/.claude/agent-references" ] && rm "$HOME/.claude/agent-references"
if [ ! -e "$HOME/.claude/agent-references" ]; then
    ln -sf "$REPO/shared/agent-references" "$HOME/.claude/agent-references"
else
    mkdir -p "$HOME/.claude/agent-references"
    for ref_file in "$REPO/shared/agent-references"/*.md; do
        ref_name="$(basename "$ref_file")"
        ln -sf "$ref_file" "$HOME/.claude/agent-references/$ref_name"
    done
fi

echo "  Agents: ~/.claude/agents/* → $REPO/shared/agents/*"
echo "  Agent references: ~/.claude/agent-references → $REPO/shared/agent-references"

# Skills (symlink each skill dir individually — don't replace existing dirs)
mkdir -p "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.agents/skills"

for skill_dir in "$REPO/shared/skills"/*/; do
    skill_name="$(basename "$skill_dir")"
    # Claude Code
    target_claude="$HOME/.claude/skills/$skill_name"
    [ -L "$target_claude" ] && rm "$target_claude"
    [ -d "$target_claude" ] && [ ! -L "$target_claude" ] && { mkdir -p "$BACKUP"; cp -r "$target_claude" "$BACKUP/"; rm -rf "$target_claude"; }
    ln -sf "$skill_dir" "$target_claude"
    # Codex
    target_codex="$HOME/.codex/skills/$skill_name"
    [ -L "$target_codex" ] && rm "$target_codex"
    [ -d "$target_codex" ] && [ ! -L "$target_codex" ] && { mkdir -p "$BACKUP"; cp -r "$target_codex" "$BACKUP/"; rm -rf "$target_codex"; }
    ln -sf "$skill_dir" "$target_codex"
    # Gemini in Android Studio discovers physical skill directories reliably;
    # do not use symlinks here.
    target_gemini="$HOME/.agents/skills/$skill_name"
    if [ -L "$target_gemini" ]; then
        rm "$target_gemini"
    elif [ -e "$target_gemini" ]; then
        mkdir -p "$BACKUP"
        cp -r "$target_gemini" "$BACKUP/"
        rm -rf "$target_gemini"
    fi
    /usr/bin/ditto "$skill_dir" "$target_gemini"
done

echo "  Skills: ~/.claude/skills/* and ~/.codex/skills/* → $REPO/shared/skills/*"
echo "  Gemini skills: ~/.agents/skills/* copied from $REPO/shared/skills/*"

# Codex
mkdir -p "$HOME/.codex"

backup_if_exists "$HOME/.codex/AGENTS.md"

ln -sf "$REPO/shared/AGENTS.md" "$HOME/.codex/AGENTS.md"

echo "  Codex: ~/.codex/AGENTS.md → $REPO/shared/AGENTS.md"

# Global neutral AGENTS.md
# Harness-specific adapters must be installed in their own runtime locations.
if [ -L "$HOME/AGENTS.md" ]; then
    echo "  Global: preserving existing ~/AGENTS.md symlink"
else
    backup_if_exists "$HOME/AGENTS.md"
    printf '%s\n' "@${REPO}/shared/global-neutral.md" > "$HOME/AGENTS.md"
    echo "  Global: ~/AGENTS.md → imports $REPO/shared/global-neutral.md"
fi

# Pi
mkdir -p "$HOME/.pi/agent" "$HOME/.pi/agent/extensions"
backup_if_exists "$HOME/.pi/agent/AGENTS.md"
ln -sf "$REPO/pi/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
for extension_file in "$REPO/pi/extensions"/*.ts; do
    [ -e "$extension_file" ] || continue
    extension_name="$(basename "$extension_file")"
    target="$HOME/.pi/agent/extensions/$extension_name"
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
