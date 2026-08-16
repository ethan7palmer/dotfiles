#!/usr/bin/env bash
#
# Install Neovim via apt. Config (home/.config/nvim/init.lua) intentionally
# not written yet — added once there's an actual config to ship.
#
set -euo pipefail

if command -v nvim >/dev/null 2>&1; then
    echo "neovim already installed — nothing to do."
else
    echo "Installing neovim..."
    sudo apt update
    sudo apt install -y neovim
fi
