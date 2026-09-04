#!/usr/bin/env bash
#
# Install a couple of commonly used CLI monitoring tools via apt: htop and
# btop (interactive process viewers - btop's the fancier, mouse-friendly
# one).
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

PACKAGES=(
    htop
    btop
)

missing=()
for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -s "${pkg}" >/dev/null 2>&1; then
        missing+=("${pkg}")
    fi
done

if [ ${#missing[@]} -eq 0 ]; then
    ok "htop and btop already installed."
else
    change "Installing: ${missing[*]}"
    sudo apt update
    sudo apt install -y "${missing[@]}"
fi
