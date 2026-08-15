#!/usr/bin/env bash
#
# Install Hack Nerd Font (Mono variant, for terminal use — strictly
# fixed-width, unlike the plain "Hack Nerd Font"/"Propo" variants) from
# Nerd Fonts' official GitHub releases. No apt package exists for Nerd
# Fonts' patched fonts, so this is a vendor-install exception, same as
# Docker/herdr. Installed user-locally (~/.local/share/fonts), no sudo.
#
set -euo pipefail

FONT_DIR="${HOME}/.local/share/fonts"

if [ -f "${FONT_DIR}/HackNerdFontMono-Regular.ttf" ]; then
    echo "Hack Nerd Font Mono already installed — nothing to do."
    exit 0
fi

echo "Installing Hack Nerd Font Mono..."

FONT_URL="$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest |
    jq -r '.assets[] | select(.name == "Hack.tar.xz") | .browser_download_url')"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

curl -fsSL "${FONT_URL}" -o "${TMP_DIR}/Hack.tar.xz"
tar -xJf "${TMP_DIR}/Hack.tar.xz" -C "${TMP_DIR}"

mkdir -p "${FONT_DIR}"
mv "${TMP_DIR}"/HackNerdFontMono-*.ttf "${FONT_DIR}/"

fc-cache -f "${FONT_DIR}" >/dev/null
