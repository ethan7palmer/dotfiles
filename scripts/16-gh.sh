#!/usr/bin/env bash
#
# Install the GitHub CLI from GitHub's own signed apt repo (Ubuntu's
# universe package lags upstream by dozens of minor versions - the same
# "prefer the vendor's repo" reasoning as Chrome/Docker/Claude Code), then
# authenticate it.
#
# Authenticating uploads the SSH key scripts/07-ssh-key.sh already
# generated to your GitHub account via `gh ssh-key add` - replacing the
# manual "paste your public key into GitHub's Settings" step this repo
# used to leave for you to do by hand (see install.sh's Phase 3 report,
# which only shows that instruction now if this didn't happen). That
# upload is fully non-interactive and idempotent (confirmed against a
# real account: re-adding an already-present key just prints "already
# exists" and exits 0) - `--skip-ssh-key` below turns off gh's own
# interactive upload prompt so this script does it directly instead,
# without asking anything.
#
# `gh ssh-key add` needs the admin:public_key token scope, which gh only
# requests on its own when you go through its interactive SSH-key prompt
# - the exact thing --skip-ssh-key turns off. So this script requests
# that scope explicitly instead (--scopes on first login; gh auth
# refresh if already logged in without it - found by actually testing
# the fresh-login path and hitting the resulting 404).
#
# The one thing that genuinely can't be automated is the OAuth device
# flow's browser approval - GitHub requires a human click there by
# design, as the actual security control proving this machine is really
# you. That's the only interactive moment in this whole repo (every
# browser approval below is a variant of it); everything else here,
# including the SSH key upload, is silent like every other script.
#
set -euo pipefail

if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    BOLD="$(tput bold)"
    RESET="$(tput sgr0)"
    YELLOW="$(tput setaf 3)"
else
    BOLD="" RESET="" YELLOW=""
fi

announce_browser_step() {
    echo
    echo "${BOLD}${YELLOW}>>> This needs you: press Enter, then click"
    echo "\"Continue\"/\"Authorize\" in the browser tab it opens. Nothing to"
    echo "type or choose - just approve it. <<<${RESET}"
    echo
}

has_scope() {
    gh api -i user 2>/dev/null | grep -i '^x-oauth-scopes:' | grep -qw "$1"
}

if ! dpkg -s gh >/dev/null 2>&1; then
    echo "Installing gh (GitHub CLI)..."

    KEYRING="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
    SOURCES_LIST="/etc/apt/sources.list.d/github-cli.list"
    REPO_LINE="deb [arch=$(dpkg --print-architecture) signed-by=${KEYRING}] https://cli.github.com/packages stable main"

    sudo install -d -m 0755 /etc/apt/keyrings

    if [ ! -s "${KEYRING}" ]; then
        echo "Downloading the GitHub CLI signing key..."
        sudo curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o "${KEYRING}"
        sudo chmod a+r "${KEYRING}"
    fi

    if [ ! -f "${SOURCES_LIST}" ] || ! grep -qxF "${REPO_LINE}" "${SOURCES_LIST}"; then
        echo "Registering the GitHub CLI apt repository..."
        echo "${REPO_LINE}" | sudo tee "${SOURCES_LIST}" >/dev/null
    fi

    sudo apt update
    sudo apt install -y gh
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "Authenticating gh - this generates an OAuth token, which is what"
    echo "gh itself uses for its own commands (gh pr create, gh issue view,"
    echo "gh api, etc) - completely separate from the SSH key below."
    announce_browser_step
    gh auth login --hostname github.com --git-protocol ssh --web \
        --skip-ssh-key --scopes admin:public_key
elif ! has_scope admin:public_key; then
    echo "gh is authenticated but missing the admin:public_key scope"
    echo "needed to upload your SSH key below - requesting it now."
    announce_browser_step
    gh auth refresh --hostname github.com --scopes admin:public_key
else
    echo "gh already authenticated — nothing to do."
fi

SSH_KEY="${HOME}/.ssh/id_ed25519"
if [ -f "${SSH_KEY}.pub" ]; then
    KEY_TITLE="$(cut -d' ' -f3- "${SSH_KEY}.pub")"
    gh ssh-key add "${SSH_KEY}.pub" --title "${KEY_TITLE}"
fi
