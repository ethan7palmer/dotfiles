#!/usr/bin/env bash
#
# lazy.nvim plugin sync, headless. Rewrites home/.config/nvim/lazy-lock.json
# in place - it's stowed, so that's the tracked file itself; review the
# diff afterward like any other tracked-file change.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

if ! command -v nvim >/dev/null 2>&1; then
    ok "Neovim isn't installed — nothing to do."
    exit 0
fi

nvim --headless "+Lazy! sync" +qa
