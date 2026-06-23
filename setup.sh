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
# Remove dir before symlinking (ln -sf won't replace an existing dir)
[ -d "$HOME/.claude/hooks" ] && [ ! -L "$HOME/.claude/hooks" ] && rm -rf "$HOME/.claude/hooks"

ln -sf "$REPO/claude/CLAUDE.md"     "$HOME/.claude/CLAUDE.md"
ln -sf "$REPO/claude/settings.json" "$HOME/.claude/settings.json"
ln -sf "$REPO/claude/hooks"         "$HOME/.claude/hooks"

echo "  Claude Code: ~/.claude/CLAUDE.md → $REPO/claude/CLAUDE.md"
echo "  Claude Code: ~/.claude/settings.json → $REPO/claude/settings.json"
echo "  Claude Code: ~/.claude/hooks → $REPO/claude/hooks"

# Skills (symlink each skill dir individually — don't replace existing dirs)
mkdir -p "$HOME/.claude/skills" "$HOME/.codex/skills"

for skill_dir in "$REPO/shared/skills"/*/; do
    skill_name="$(basename "$skill_dir")"
    # Claude Code
    target_claude="$HOME/.claude/skills/$skill_name"
    [ -d "$target_claude" ] && [ ! -L "$target_claude" ] && { mkdir -p "$BACKUP"; cp -r "$target_claude" "$BACKUP/"; rm -rf "$target_claude"; }
    ln -sf "$skill_dir" "$target_claude"
    # Codex
    target_codex="$HOME/.codex/skills/$skill_name"
    [ -d "$target_codex" ] && [ ! -L "$target_codex" ] && { mkdir -p "$BACKUP"; cp -r "$target_codex" "$BACKUP/"; rm -rf "$target_codex"; }
    ln -sf "$skill_dir" "$target_codex"
done

echo "  Skills: ~/.claude/skills/* and ~/.codex/skills/* → $REPO/shared/skills/*"

# Codex
mkdir -p "$HOME/.codex"

backup_if_exists "$HOME/.codex/AGENTS.md"

ln -sf "$REPO/shared/AGENTS.md" "$HOME/.codex/AGENTS.md"

echo "  Codex: ~/.codex/AGENTS.md → $REPO/shared/AGENTS.md"

# csync alias hint
echo ""
echo "Add to ~/.zshrc or ~/.bashrc:"
echo "  alias csync='cd \$HOME/dotfiles/ai && git add -A && git commit -m \"sync: \$(hostname) \$(date +%Y-%m-%d)\" && git push && cd -'"
echo ""
echo "Done."
