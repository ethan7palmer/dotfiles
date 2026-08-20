#!/usr/bin/env bash
#
# Install tmux via apt. Its keybindings (home/.config/tmux/tmux.conf) are
# deliberately made to match herdr's (home/.config/herdr/config.toml's
# [keys] table) so switching between the two doesn't mean re-learning
# muscle memory - independent of whether herdr is installed too; see
# tmux.conf itself for exactly which keys differ from tmux's own
# defaults and why.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

if command -v tmux >/dev/null 2>&1; then
    ok "tmux already installed — nothing to do."
else
    change "Installing tmux..."
    sudo apt update
    sudo apt install -y tmux
fi
