#!/bin/bash
# Branch guard: warns when editing files on protected branches.
# Exceptions:
#   - ~/dotfiles/ai config repo is always edited on main/master
#   - Gitignored files don't require a worktree

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', d)
    print(ti.get('file_path', ti.get('filePath', '')))
except Exception:
    print('')
" 2>/dev/null)

case "$FILE_PATH" in
    */swarm-report/*|swarm-report/*) exit 0 ;;
esac

if [ -n "$FILE_PATH" ] && [ -e "$(dirname "$FILE_PATH")" ]; then
    CHECK_DIR="$(dirname "$FILE_PATH")"
else
    CHECK_DIR="$(pwd)"
fi

# Skip for ~/dotfiles/ai config repo — always works on main/master
GIT_ROOT=$(git -C "$CHECK_DIR" rev-parse --show-toplevel 2>/dev/null)
if [ -n "$GIT_ROOT" ] && [ "$(cd "$GIT_ROOT" 2>/dev/null && pwd -P)" = "$(cd "$HOME/dotfiles/ai" 2>/dev/null && pwd -P)" ]; then
    exit 0
fi

# Skip for GitHub Wiki repos
REMOTE_URL=$(git -C "$CHECK_DIR" remote get-url origin 2>/dev/null)
if [[ "$REMOTE_URL" == *.wiki.git ]]; then
    exit 0
fi

BRANCH=$(git -C "$CHECK_DIR" branch --show-current 2>/dev/null)
if [ $? -ne 0 ]; then
    exit 0
fi

if [ -n "$FILE_PATH" ] && git -C "$CHECK_DIR" check-ignore -q "$FILE_PATH" 2>/dev/null; then
    exit 0
fi

if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ] || [ "$BRANCH" = "develop" ] || [ "$BRANCH" = "dev" ] || [ "$BRANCH" = "development" ]; then
    echo "BRANCH: You are on the '$BRANCH' branch. You usually work in a separate feature branch." >&2
    echo "Please confirm this is intentional before proceeding." >&2
    exit 2
fi

exit 0
