#!/usr/bin/env bash
#
# Install Godot 4 (the standard, GDScript-only editor - no C#/.NET
# runtime) from Godot's own official GitHub releases. Ubuntu's apt repo
# only has the old godot3 package (stuck on the 3.6 branch); the current
# 4.x line has no apt/vendor-repo package at all, so this is a direct
# download, same trust tier as herdr (see README's "Where things come
# from"): fetched over HTTPS straight from GitHub and checked against a
# SHA512 manifest published in the same release. That catches
# corruption/CDN issues, not a compromise of the release itself the way
# Handy's minisign signature does - Godot doesn't publish one.
#
# Installed as a single self-contained binary to ~/.local/bin, no sudo.
# A .desktop entry makes it show up in the GNOME app grid; this script
# fetches the matching official icon for it into the user-local hicolor
# icon theme ($XDG_DATA_HOME/icons/hicolor - the icon-theme spec's
# user-local equivalent of ~/.local/share/applications for desktop
# files; the app_icon.png source Godot ships is 128x128, hence that size
# bucket).
#
# The .desktop file is generated here, not a static file Stow symlinks
# in like home/.local/share/applications/google-chrome.desktop - its
# Exec key needs this machine's real, already-resolved absolute path
# (~/.local/bin isn't on gnome-shell's own PATH, only interactive
# shells' - see home/.config/environment.d/999-local-bin-path.conf's
# comment - and unlike a plain shell prompt, a .desktop file's Exec
# value is never passed through a shell, so "~" or "$HOME" in it would
# be taken completely literally, not expanded).
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

BIN_DIR="${HOME}/.local/bin"
GODOT_BIN="${BIN_DIR}/godot"
ICON_DIR="${HOME}/.local/share/icons/hicolor/128x128/apps"
DESKTOP_FILE="${HOME}/.local/share/applications/godot.desktop"

# Godot tags every stable release "<version>-stable" regardless of major
# version (3.6.3-stable, 4.7.2-stable, ...), and GitHub's "latest release"
# is whichever tag was published most recently - not necessarily the
# newest 4.x one, since the 3.6 branch still gets occasional maintenance
# releases. List releases and take the newest tag actually matching
# 4.*-stable instead of trusting /releases/latest.
TAG="$(curl -fsSL "https://api.github.com/repos/godotengine/godot-builds/releases?per_page=30" |
    jq -r '.[] | select(.tag_name | test("^4\\..*-stable$")) | .tag_name' | head -1)"

if [ -z "${TAG}" ]; then
    err "Could not find a Godot 4.x stable release on GitHub."
    exit 1
fi

# `godot --version` reports e.g. "4.7.2.stable.official.ed1daf0bf" for
# tag "4.7.2-stable" - same string, "-stable" spelled ".stable".
EXPECTED_VERSION_PREFIX="${TAG/-stable/.stable}"

if [ -x "${GODOT_BIN}" ] && "${GODOT_BIN}" --version --headless 2>/dev/null | grep -qF "${EXPECTED_VERSION_PREFIX}"; then
    ok "Godot ${EXPECTED_VERSION_PREFIX} already installed — nothing to do."
else
    change "Installing Godot ${TAG}..."

    ZIP_NAME="Godot_v${TAG}_linux.x86_64.zip"
    BASE_URL="https://github.com/godotengine/godot-builds/releases/download/${TAG}"

    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "${TMP_DIR}"' EXIT

    curl -fsSL "${BASE_URL}/${ZIP_NAME}" -o "${TMP_DIR}/${ZIP_NAME}"
    curl -fsSL "${BASE_URL}/SHA512-SUMS.txt" -o "${TMP_DIR}/SHA512-SUMS.txt"

    change "Verifying checksum..."
    (cd "${TMP_DIR}" && grep " ${ZIP_NAME}\$" SHA512-SUMS.txt | sha512sum -c -)

    unzip -q -o "${TMP_DIR}/${ZIP_NAME}" -d "${TMP_DIR}"

    mkdir -p "${BIN_DIR}"
    install -m 0755 "${TMP_DIR}/Godot_v${TAG}_linux.x86_64" "${GODOT_BIN}"
fi

mkdir -p "${ICON_DIR}"
if [ ! -f "${ICON_DIR}/godot.png" ]; then
    change "Installing Godot's app icon..."
    curl -fsSL "https://raw.githubusercontent.com/godotengine/godot/${TAG}/main/app_icon.png" -o "${ICON_DIR}/godot.png"
fi

mkdir -p "$(dirname "${DESKTOP_FILE}")"
cat >"${DESKTOP_FILE}" <<EOF
[Desktop Entry]
Name=Godot Engine
GenericName=Libre game engine
Comment=Multi-platform 2D and 3D game engine with a feature-rich editor
Keywords=game development;development;IDE;game engine;
Exec=${GODOT_BIN} %f
Icon=godot
Terminal=false
Type=Application
MimeType=application/x-godot-project;
Categories=Development;IDE;
StartupWMClass=Godot
EOF
