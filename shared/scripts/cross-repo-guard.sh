#!/bin/bash
# Cross-repo guard: warns when editing a file outside the current git repo/worktree

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)

def pick(obj):
    if not isinstance(obj, dict):
        return ""
    for key in ("file_path", "filePath", "path"):
        value = obj.get(key)
        if isinstance(value, str) and value:
            return value
    return ""

for candidate in (
    d,
    d.get("tool_input"),
    d.get("toolInput"),
    d.get("tool_response"),
    d.get("toolResponse"),
):
    path = pick(candidate)
    if path:
        print(path)
        break
' 2>/dev/null)

[ -z "$FILE_PATH" ] && exit 0

CWD_GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[ -z "$CWD_GIT_ROOT" ] && exit 0

[ -e "$(dirname "$FILE_PATH")" ] || exit 0

FILE_GIT_ROOT=$(git -C "$(dirname "$FILE_PATH")" rev-parse --show-toplevel 2>/dev/null)
[ -z "$FILE_GIT_ROOT" ] && exit 0

if [ "$CWD_GIT_ROOT" != "$FILE_GIT_ROOT" ]; then
    echo "CROSS-REPO: File '$FILE_PATH' belongs to a different git repo/worktree."
    echo "  Current worktree: $CWD_GIT_ROOT"
    echo "  File worktree:    $FILE_GIT_ROOT"
    echo ""
    echo "Please confirm this is intentional before proceeding."
    exit 2
fi

exit 0
