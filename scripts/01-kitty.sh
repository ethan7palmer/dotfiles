#!/usr/bin/env bash
#
# Install Kitty terminal emulator via apt.
#
set -euo pipefail

if dpkg -s kitty >/dev/null 2>&1; then
    echo "kitty already installed — nothing to do."
    exit 0
fi

echo "Installing kitty..."
sudo apt update
sudo apt install -y kitty
