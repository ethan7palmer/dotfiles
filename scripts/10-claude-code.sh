#!/usr/bin/env bash
#
# Install Claude Code from Anthropic's signed apt repository.
#
# Anthropic publishes an official apt repo, so per the "always prefer apt"
# rule that is what this uses. The native install script is kept only as a
# loud fallback for the case where apt genuinely cannot install the package
# (e.g. an unsupported architecture).
#
# Docs: https://code.claude.com/docs/en/setup
#
set -euo pipefail

KEYRING="/etc/apt/keyrings/claude-code.asc"
KEY_URL="https://downloads.claude.ai/keys/claude-code.asc"
SOURCES_LIST="/etc/apt/sources.list.d/claude-code.list"
# "stable" trails latest by roughly a week and skips releases with known
# major regressions. Change both occurrences below to use "latest".
CHANNEL="stable"
REPO_LINE="deb [signed-by=${KEYRING}] https://downloads.claude.ai/claude-code/apt/${CHANNEL} ${CHANNEL} main"
EXPECTED_FPR="31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE"

install_via_apt() {
    sudo install -d -m 0755 /etc/apt/keyrings

    if [ ! -s "${KEYRING}" ]; then
        echo "Downloading the Claude Code signing key..."
        sudo curl -fsSL "${KEY_URL}" -o "${KEYRING}"
    fi

    # Never trust the key without checking it, including on re-runs where the
    # file was already on disk.
    actual_fpr="$(gpg --show-keys --with-colons "${KEYRING}" |
        awk -F: '$1 == "fpr" { print $10; exit }')"
    if [ "${actual_fpr}" != "${EXPECTED_FPR}" ]; then
        echo "ERROR: signing key fingerprint mismatch at ${KEYRING}" >&2
        echo "  expected: ${EXPECTED_FPR}" >&2
        echo "  actual:   ${actual_fpr:-<no valid OpenPGP data>}" >&2
        return 1
    fi

    if [ ! -f "${SOURCES_LIST}" ] || ! grep -qxF "${REPO_LINE}" "${SOURCES_LIST}"; then
        echo "Registering the Claude Code apt repository (${CHANNEL} channel)..."
        echo "${REPO_LINE}" | sudo tee "${SOURCES_LIST}" >/dev/null
    fi

    sudo apt update
    sudo apt install -y claude-code
}

install_via_official_script() {
    echo "Falling back to the official install script." >&2
    curl -fsSL https://claude.ai/install.sh | bash -s "${CHANNEL}"
}

if dpkg -s claude-code >/dev/null 2>&1; then
    echo "claude-code already installed via apt — nothing to do."
    echo "  (upgrade with: sudo apt update && sudo apt upgrade claude-code)"
elif command -v claude >/dev/null 2>&1; then
    echo "claude already installed at $(command -v claude) — leaving it alone."
    echo "  (upgrade with: claude update)"
elif install_via_apt; then
    :
else
    echo "WARNING: apt install of claude-code failed." >&2
    install_via_official_script
fi

# Report the version so a failed install can't pass silently. The native
# install script puts claude in ~/.local/bin, which may not be on PATH yet.
if command -v claude >/dev/null 2>&1; then
    claude --version
elif [ -x "${HOME}/.local/bin/claude" ]; then
    "${HOME}/.local/bin/claude" --version
else
    echo "ERROR: claude was not found after installation." >&2
    exit 1
fi
