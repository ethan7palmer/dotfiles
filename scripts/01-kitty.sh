#!/usr/bin/env bash
#
# Install Kitty terminal emulator via apt.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

if dpkg -s kitty >/dev/null 2>&1; then
    ok "kitty already installed — nothing to do."
    exit 0
fi

change "Installing kitty..."
sudo apt update
sudo apt install -y kitty
