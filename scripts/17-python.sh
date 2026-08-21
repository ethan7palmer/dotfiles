#!/usr/bin/env bash
#
# Install Python via apt: the interpreter (already on Ubuntu by default,
# listed anyway for a complete/idempotent check), the venv module (split
# out of the base python3 package - needed to create virtual
# environments, the standard way to isolate a project's dependencies),
# pip, and pipx (the recommended way to install Python CLI *tools* like
# black/poetry/ruff in their own isolated environment instead of
# polluting the system interpreter - Ubuntu's system Python is
# "externally managed" per PEP 668, so a plain `pip install` outside a
# venv now refuses to run at all).
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

PACKAGES=(
    python3
    python3-venv
    python3-pip
    pipx
)

missing=()
for pkg in "${PACKAGES[@]}"; do
    dpkg -s "${pkg}" >/dev/null 2>&1 || missing+=("${pkg}")
done

if [ ${#missing[@]} -eq 0 ]; then
    ok "Python already installed — nothing to do."
else
    change "Installing: ${missing[*]}"
    sudo apt update
    sudo apt install -y "${missing[@]}"
fi

# Deliberately not running `pipx ensurepath` - pipx installs to
# ~/.local/bin by default, which home/.bashrc and home/.zshrc already put
# on PATH themselves. `pipx ensurepath` would otherwise try to append its
# own PATH line directly into those tracked, Stow-symlinked files.
