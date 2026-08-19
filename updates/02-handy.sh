#!/usr/bin/env bash
#
# Handy ships as a signed GitHub release .deb with no apt repo behind it
# (see scripts/15-handy.sh), so apt upgrades never see new versions -
# this checks GitHub's latest release against what's installed and, if
# it's newer, reinstalls it the same way scripts/15-handy.sh originally
# did: minisign-verified before `apt install`.
#
set -euo pipefail

if ! dpkg -s handy >/dev/null 2>&1; then
    echo "Handy isn't installed — nothing to do."
    exit 0
fi

if ! dpkg -s minisign >/dev/null 2>&1; then
    echo "Installing minisign (used to verify Handy's release signature)..."
    sudo apt update
    sudo apt install -y minisign
fi

source "$(dirname "$0")/../lib/handy-pubkey.sh"

RELEASE_JSON="$(curl -fsSL https://api.github.com/repos/cjpais/Handy/releases/latest)"
LATEST_VERSION="$(jq -r '.tag_name' <<<"${RELEASE_JSON}" | sed 's/^v//')"
INSTALLED_VERSION="$(dpkg-query -W -f='${Version}' handy)"

if [ "${LATEST_VERSION}" = "${INSTALLED_VERSION}" ]; then
    echo "Handy ${INSTALLED_VERSION} is already the latest — nothing to do."
    exit 0
fi

echo "Updating Handy ${INSTALLED_VERSION} -> ${LATEST_VERSION}..."

DEB_URL="$(jq -r '.assets[] | select(.name | test("amd64\\.deb$")) | .browser_download_url' <<<"${RELEASE_JSON}")"
SIG_URL="$(jq -r '.assets[] | select(.name | test("amd64\\.deb\\.sig$")) | .browser_download_url' <<<"${RELEASE_JSON}")"
DEB_NAME="$(basename "${DEB_URL}")"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

curl -fsSL "${DEB_URL}" -o "${TMP_DIR}/${DEB_NAME}"
curl -fsSL "${SIG_URL}" -o "${TMP_DIR}/${DEB_NAME}.sig"

base64 -d <<<"${HANDY_PUBKEY_B64}" >"${TMP_DIR}/handy.pub"
# Handy's .sig release assets are themselves base64-encoded text wrapping
# the actual minisign signature - see Handy's README, "Verify Release
# Signatures".
base64 -d "${TMP_DIR}/${DEB_NAME}.sig" >"${TMP_DIR}/${DEB_NAME}.minisig"

echo "Verifying signature..."
minisign -Vm "${TMP_DIR}/${DEB_NAME}" -p "${TMP_DIR}/handy.pub" -x "${TMP_DIR}/${DEB_NAME}.minisig"

# The new .deb takes effect on next launch, not for a copy of Handy
# already running off the old binary - restart it if it's up so the
# upgrade doesn't silently sit unused until the next login.
was_running=false
if pgrep -x handy >/dev/null 2>&1; then
    was_running=true
    pkill -x handy || true
    for _ in $(seq 1 20); do
        pgrep -x handy >/dev/null 2>&1 || break
        sleep 0.5
    done
fi

echo "Installing ${DEB_NAME}..."
sudo apt install -y "${TMP_DIR}/${DEB_NAME}"

if [ "${was_running}" = true ]; then
    echo "Restarting Handy..."
    nohup /usr/bin/handy --start-hidden >/dev/null 2>&1 &
    disown
fi
