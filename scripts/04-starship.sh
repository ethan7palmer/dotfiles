#!/usr/bin/env bash
#
# Install Starship (cross-shell prompt) via apt.
#
set -euo pipefail

if command -v starship >/dev/null 2>&1; then
    echo "starship already installed — nothing to do."
else
    echo "Installing starship..."
    sudo apt update
    sudo apt install -y starship
fi
