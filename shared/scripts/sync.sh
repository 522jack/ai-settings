#!/bin/bash
# Commit and push ~/dotfiles/ai settings. Usage: csync

set -euo pipefail

LOCK="/tmp/.dotfiles-ai-sync.lock"
exec 9>"$LOCK"
perl -e 'use Fcntl qw(:flock); open(F, ">&=9"); flock(F, LOCK_EX|LOCK_NB) or die' 2>/dev/null \
  || { echo "Another csync is running."; exit 1; }

cd "$HOME/dotfiles/ai"

# Clean up stale rebase state
if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
  git rebase --abort 2>/dev/null
fi

# Check upstream is configured
if ! git rev-parse --abbrev-ref '@{upstream}' &>/dev/null; then
  echo "No upstream configured. Run: git -C ~/dotfiles/ai branch --set-upstream-to=origin/master"
  exit 1
fi

# Commit local changes
git add -A
if ! git diff --cached --quiet; then
  git commit --quiet -m "sync $(hostname -s) $(date +%Y-%m-%d\ %H:%M)"
  echo "Committed."
else
  echo "No local changes."
fi

# Pull remote
git fetch --quiet origin 2>/dev/null || { echo "Fetch failed (network?)."; exit 1; }
UPSTREAM=$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || echo "origin/master")

if ! git rebase --quiet "$UPSTREAM"; then
  git rebase --abort 2>/dev/null
  for file in $(git diff --name-only HEAD "$UPSTREAM" 2>/dev/null); do
    git show "$UPSTREAM:$file" > "$HOME/dotfiles/ai/$file.remote" 2>/dev/null
  done
  echo "Conflict. Remote versions saved as *.remote."
  echo "Merge them with your local files, delete .remote, then run csync again."
  exit 1
fi

# Push
if [ "$(git rev-list --count '@{u}..HEAD')" -gt 0 ]; then
  git push --quiet && echo "Pushed." || { echo "Push failed."; exit 1; }
else
  echo "Up to date."
fi
