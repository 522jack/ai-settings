#!/bin/bash
# Auto-sync ~/dotfiles/ai on session start: commit local edits, rebase on remote, push.
#
# Never fail silently. Every non-OK outcome is recorded via three channels:
#   - ~/.dotfiles-ai-sync-status (rendered in statusline)
#   - OS notification on hard failures
#   - stdout (Claude/Codex relays)
# Always exits 0 so it can never break a session.

set -uo pipefail

REPO="$HOME/dotfiles/ai"
STATUS="$HOME/.dotfiles-ai-sync-status"

cd "$REPO" 2>/dev/null || exit 0

# Recursion guard: csync exports CLAUDE_SYNC_ACTIVE=1
[ -n "${CLAUDE_SYNC_ACTIVE:-}" ] && exit 0

git rev-parse --git-dir >/dev/null 2>&1 || exit 0
git remote get-url origin >/dev/null 2>&1 || exit 0

note()  { printf '[ai-sync] %s\n' "$*"; }
warn()  { printf '%s' "$*" > "$STATUS"; printf '⚠ ~/dotfiles/ai: %s\n' "$*"; }
alarm() {
  printf '%s' "$*" > "$STATUS"
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$*\" with title \"~/dotfiles/ai sync\"" >/dev/null 2>&1 || true
  fi
  printf '⚠ ~/dotfiles/ai: %s\n' "$*"
}
clear_status() { rm -f "$STATUS" 2>/dev/null || true; }

# Clean up stale rebase state from a previous crash
if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
  git rebase --abort 2>/dev/null || true
fi

# Commit local edits
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
  if ! git add -A 2>/dev/null || ! git commit --quiet -m "[auto-pull] save local $(hostname -s)" 2>/dev/null; then
    alarm "cannot commit local edits — sync skipped; fix git state in ~/dotfiles/ai"
    exit 0
  fi
fi

# Fetch
if ! git fetch --quiet origin 2>/dev/null; then
  warn "offline — sync state unverified"
  exit 0
fi

UPSTREAM=$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || echo origin/master)
BEHIND=$(git rev-list --count "HEAD..$UPSTREAM" 2>/dev/null || echo 0)

if [ "$BEHIND" -gt 0 ]; then
  if ! git rebase --quiet "$UPSTREAM" 2>/dev/null; then
    git rebase --abort 2>/dev/null || true
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      git show "$UPSTREAM:$f" > "$REPO/$f.remote" 2>/dev/null || true
    done < <(git diff --name-only HEAD "$UPSTREAM" 2>/dev/null)
    alarm "merge conflict — remote saved as *.remote; merge them and run csync"
    exit 0
  fi
fi

AHEAD=$(git rev-list --count "$UPSTREAM..HEAD" 2>/dev/null || echo 0)
if [ "$AHEAD" -gt 0 ]; then
  if git push --quiet 2>/dev/null; then
    clear_status
    note "synced (pushed $AHEAD, pulled $BEHIND)"
  else
    alarm "push failed — $AHEAD local commit(s) NOT synced; run csync"
    exit 0
  fi
else
  clear_status
  [ "$BEHIND" -gt 0 ] && note "synced (pulled $BEHIND)"
fi

exit 0
