#!/usr/bin/env bash
#
# Install Neovim via apt. Config (home/.config/nvim/init.lua) intentionally
# not written yet — added once there's an actual config to ship.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

if command -v nvim >/dev/null 2>&1; then
    ok "neovim already installed — nothing to do."
else
    change "Installing neovim..."
    sudo apt update
    sudo apt install -y neovim
fi
