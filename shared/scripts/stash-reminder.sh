#!/bin/bash
# Stash reminder: warns before switching branches if there are uncommitted changes

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('command',''))" 2>/dev/null)

if ! echo "$COMMAND" | grep -qE 'git\s+(checkout|switch)\s'; then
    exit 0
fi

if echo "$COMMAND" | grep -qE 'git\s+stash'; then
    exit 0
fi

DIRTY_COUNT=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$DIRTY_COUNT" -gt 0 ]; then
    DIRTY_FILES=$(git status --porcelain 2>/dev/null | head -5)
    echo "STASH REMINDER: You have $DIRTY_COUNT uncommitted change(s) and are about to switch branches."
    echo "$DIRTY_FILES"
    if [ "$DIRTY_COUNT" -gt 5 ]; then
        echo "  ...and $((DIRTY_COUNT - 5)) more files"
    fi
    echo ""
    echo "Consider running 'git stash' or committing before switching."
    echo "Please confirm you want to proceed."
    exit 2
fi

exit 0
