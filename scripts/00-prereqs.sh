#!/usr/bin/env bash
#
# Install what the remaining scripts require, plus a couple of general CLI
# tools used across configs (ripgrep/fd for Neovim's fuzzy pickers).
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

PACKAGES=(
    curl
    wget
    stow
    gnupg
    ca-certificates
    software-properties-common
    jq
    ripgrep
    fd-find
)

missing=()
for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -s "${pkg}" >/dev/null 2>&1; then
        missing+=("${pkg}")
    fi
done

if [ ${#missing[@]} -eq 0 ]; then
    ok "All prerequisites already installed."
else
    change "Installing: ${missing[*]}"
    sudo apt update
    sudo apt install -y "${missing[@]}"
fi

# Ubuntu's fd-find package installs the binary as `fdfind`, not `fd` (name
# clash with an unrelated existing package) — symlink it so anything
# looking for `fd` on PATH (e.g. Neovim's file picker) finds it.
if [ ! -e /usr/local/bin/fd ]; then
    sudo ln -s "$(command -v fdfind)" /usr/local/bin/fd
fi
