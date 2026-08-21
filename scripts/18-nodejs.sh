#!/usr/bin/env bash
#
# Install Node.js via NodeSource's own signed apt repo - Ubuntu's own
# nodejs package lags upstream by entire major versions, the same
# "prefer the vendor's repo" reasoning as Chrome/Docker/Claude Code/gh.
# npm comes bundled with the nodejs package itself, no separate install.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

# 24.x is Node's current LTS ("Krypton") - the line day-to-day work
# wants, not 26.x (Current, not yet LTS as of this writing).
NODE_MAJOR="24"

if ! dpkg -s nodejs >/dev/null 2>&1; then
    change "Installing Node.js ${NODE_MAJOR}.x..."

    KEYRING="/etc/apt/keyrings/nodesource.gpg"
    SOURCES_LIST="/etc/apt/sources.list.d/nodesource.list"
    REPO_LINE="deb [signed-by=${KEYRING}] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main"

    sudo install -d -m 0755 /etc/apt/keyrings

    # NodeSource serves an ASCII-armored key block despite the .key
    # extension, not a binary keyring - apt's signed-by= rejects that
    # outright ("unsupported filetype"), so dearmor it on the way in, same
    # as Chrome's/Docker's signing keys in this repo. Re-checked (not just
    # "does the file exist") so a keyring saved armored by an earlier,
    # pre-fix run of this script gets repaired instead of silently staying
    # broken forever.
    if [ ! -s "${KEYRING}" ] || grep -qa "BEGIN PGP" "${KEYRING}"; then
        change "Downloading the NodeSource signing key..."
        # --yes: the repair path above can hit an existing (stale) file at
        # ${KEYRING} - gpg --dearmor -o prompts "Overwrite? (y/N)" for
        # that by default, which would hang a script meant to run
        # unattended. Nothing to overwrite on a genuinely fresh machine,
        # but this shouldn't depend on that being true to behave
        # correctly either way.
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key |
            sudo gpg --yes --dearmor -o "${KEYRING}"
        sudo chmod a+r "${KEYRING}"
    fi

    if [ ! -f "${SOURCES_LIST}" ] || ! grep -qxF "${REPO_LINE}" "${SOURCES_LIST}"; then
        change "Registering the NodeSource apt repository..."
        echo "${REPO_LINE}" | sudo tee "${SOURCES_LIST}" >/dev/null
    fi

    sudo apt update
    sudo apt install -y nodejs
else
    ok "Node.js already installed at $(command -v node) — leaving it alone."
fi
