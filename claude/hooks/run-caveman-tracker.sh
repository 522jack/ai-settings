#!/usr/bin/env bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" --no-use 2>/dev/null
NODE=$(command -v node 2>/dev/null || echo "$NVM_DIR/versions/node/$(ls $NVM_DIR/versions/node/ 2>/dev/null | sort -V | tail -1)/bin/node")
exec "$NODE" "$HOME/dotfiles/ai/claude/hooks/caveman-mode-tracker.js"
