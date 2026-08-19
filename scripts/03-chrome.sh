#!/usr/bin/env bash
#
# Install Google Chrome via Google's official apt repository.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

if dpkg -s google-chrome-stable >/dev/null 2>&1; then
    ok "google-chrome-stable already installed — nothing to do."
    exit 0
fi

KEYRING="/etc/apt/keyrings/google-chrome.gpg"
SOURCES_LIST="/etc/apt/sources.list.d/google-chrome.list"
REPO_LINE="deb [arch=amd64 signed-by=${KEYRING}] http://dl.google.com/linux/chrome/deb/ stable main"

sudo install -d -m 0755 /etc/apt/keyrings

if [ ! -s "${KEYRING}" ]; then
    change "Downloading the Google Chrome signing key..."
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub |
        sudo gpg --dearmor -o "${KEYRING}"
fi

if [ ! -f "${SOURCES_LIST}" ] || ! grep -qxF "${REPO_LINE}" "${SOURCES_LIST}"; then
    change "Registering the Google Chrome apt repository..."
    echo "${REPO_LINE}" | sudo tee "${SOURCES_LIST}" >/dev/null
fi

change "Installing google-chrome-stable..."
sudo apt update
sudo apt install -y google-chrome-stable
