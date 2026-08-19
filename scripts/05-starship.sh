#!/usr/bin/env bash
#
# Install Starship (cross-shell prompt) via apt.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

if command -v starship >/dev/null 2>&1; then
    ok "starship already installed — nothing to do."
else
    change "Installing starship..."
    sudo apt update
    sudo apt install -y starship
fi
