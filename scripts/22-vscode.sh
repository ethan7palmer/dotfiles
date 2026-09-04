#!/usr/bin/env bash
#
# Install VS Code via Microsoft's official apt repository, plus the one
# extension its pre-seeded settings.json needs: mvllow.rose-pine, so its
# color theme matches Kitty/Neovim's Rosé Pine Moon (see
# home/.config/Code/User/settings.json). Not the daily driver (Neovim is) -
# just kept installed for the occasional time it's genuinely the better
# tool for the job.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

if dpkg -s code >/dev/null 2>&1; then
    ok "code already installed — nothing to do."
else
    KEYRING="/etc/apt/keyrings/packages.microsoft.gpg"
    SOURCES_LIST="/etc/apt/sources.list.d/vscode.list"
    REPO_LINE="deb [arch=amd64,arm64,armhf signed-by=${KEYRING}] https://packages.microsoft.com/repos/code stable main"

    sudo install -d -m 0755 /etc/apt/keyrings

    if [ ! -s "${KEYRING}" ]; then
        change "Downloading the Microsoft signing key..."
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc |
            sudo gpg --dearmor -o "${KEYRING}"
    fi

    if [ ! -f "${SOURCES_LIST}" ] || ! grep -qxF "${REPO_LINE}" "${SOURCES_LIST}"; then
        change "Registering the VS Code apt repository..."
        echo "${REPO_LINE}" | sudo tee "${SOURCES_LIST}" >/dev/null
    fi

    change "Installing code..."
    sudo apt update
    sudo apt install -y code
fi

if code --list-extensions | grep -qxF "mvllow.rose-pine"; then
    ok "mvllow.rose-pine already installed — nothing to do."
else
    change "Installing the Rosé Pine theme extension..."
    code --install-extension mvllow.rose-pine
fi
