#!/usr/bin/env bash
#
# Install only what the remaining scripts strictly require.
#
set -euo pipefail

PACKAGES=(
    curl
    wget
    stow
    gnupg
    ca-certificates
    software-properties-common
    jq
)

missing=()
for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -s "${pkg}" >/dev/null 2>&1; then
        missing+=("${pkg}")
    fi
done

if [ ${#missing[@]} -eq 0 ]; then
    echo "All prerequisites already installed."
    exit 0
fi

echo "Installing: ${missing[*]}"
sudo apt update
sudo apt install -y "${missing[@]}"
