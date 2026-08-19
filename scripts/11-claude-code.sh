#!/usr/bin/env bash
#
# Install Claude Code from Anthropic's signed apt repository.
#
# Anthropic publishes an official apt repo, so per the "always prefer apt"
# rule that is what this uses. If this fails, that's a real problem worth
# looking at (network, repo down, key rotated) rather than something to
# paper over by trying a different install method.
#
# Docs: https://code.claude.com/docs/en/setup
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

if dpkg -s claude-code >/dev/null 2>&1; then
    ok "claude-code already installed via apt — nothing to do."
    echo "  (upgrade with: sudo apt update && sudo apt upgrade claude-code)"
    exit 0
elif command -v claude >/dev/null 2>&1; then
    ok "claude already installed at $(command -v claude) — leaving it alone."
    echo "  (upgrade with: claude update)"
    exit 0
fi

KEYRING="/etc/apt/keyrings/claude-code.asc"
KEY_URL="https://downloads.claude.ai/keys/claude-code.asc"
SOURCES_LIST="/etc/apt/sources.list.d/claude-code.list"
# "stable" trails latest by roughly a week and skips releases with known
# major regressions. Change both occurrences below to use "latest".
CHANNEL="stable"
REPO_LINE="deb [signed-by=${KEYRING}] https://downloads.claude.ai/claude-code/apt/${CHANNEL} ${CHANNEL} main"
EXPECTED_FPR="31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE"

sudo install -d -m 0755 /etc/apt/keyrings

if [ ! -s "${KEYRING}" ]; then
    change "Downloading the Claude Code signing key..."
    sudo curl -fsSL "${KEY_URL}" -o "${KEYRING}"
fi

# Never trust the key without checking it, including on re-runs where the
# file was already on disk.
actual_fpr="$(gpg --show-keys --with-colons "${KEYRING}" |
    awk -F: '$1 == "fpr" { print $10; exit }')"
if [ "${actual_fpr}" != "${EXPECTED_FPR}" ]; then
    err "signing key fingerprint mismatch at ${KEYRING}"
    echo "${RED}  expected: ${EXPECTED_FPR}${RESET}" >&2
    echo "${RED}  actual:   ${actual_fpr:-<no valid OpenPGP data>}${RESET}" >&2
    exit 1
fi

if [ ! -f "${SOURCES_LIST}" ] || ! grep -qxF "${REPO_LINE}" "${SOURCES_LIST}"; then
    change "Registering the Claude Code apt repository (${CHANNEL} channel)..."
    echo "${REPO_LINE}" | sudo tee "${SOURCES_LIST}" >/dev/null
fi

sudo apt update
sudo apt install -y claude-code
claude --version
