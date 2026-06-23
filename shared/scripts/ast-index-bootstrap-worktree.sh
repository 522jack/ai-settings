#!/usr/bin/env bash
# PostToolUse:EnterWorktree — bootstrap the ast-index for a freshly-entered worktree.

set -u

INPUT="$(cat)"

printf '%s' "$INPUT" > /tmp/ast-index-worktree-hook.json 2>/dev/null || true

WT_PATH="$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
def dig(obj):
    if not isinstance(obj, dict):
        return ""
    for k in ("worktreePath", "worktree_path", "path", "worktree", "dir", "cwd"):
        v = obj.get(k)
        if isinstance(v, str) and v:
            return v
    return ""
for key in ("tool_response", "toolResponse", "tool_input", "toolInput"):
    p = dig(d.get(key))
    if p:
        print(p)
        break
' 2>/dev/null || true)"

if [ -n "$WT_PATH" ] && [ -d "$WT_PATH" ]; then
  cd "$WT_PATH" 2>/dev/null || true
fi

ast-index update 2>/dev/null || ast-index rebuild 2>/dev/null || true

if ast-index stats >/dev/null 2>&1; then
  ( nohup ast-index watch >/dev/null 2>&1 & ) || true
fi
