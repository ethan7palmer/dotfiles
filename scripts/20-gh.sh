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
# used to leave for you to do by hand (install.sh's Phase 3 report only
# shows that instruction now if this stage is skipped entirely). That
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
source "$(dirname "$0")/../lib/colors.sh"

announce_browser_step() {
    echo
    echo "${BOLD}${MAGENTA}>>> This needs you: press Enter, then click"
    echo "\"Continue\"/\"Authorize\" in the browser tab it opens. Nothing to"
    echo "type or choose - just approve it. <<<${RESET}"
    echo
}

has_scope() {
    gh api -i user 2>/dev/null | grep -i '^x-oauth-scopes:' | grep -qw "$1"
}

if ! dpkg -s gh >/dev/null 2>&1; then
    change "Installing gh (GitHub CLI)..."

    KEYRING="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
    SOURCES_LIST="/etc/apt/sources.list.d/github-cli.list"
    REPO_LINE="deb [arch=$(dpkg --print-architecture) signed-by=${KEYRING}] https://cli.github.com/packages stable main"

    sudo install -d -m 0755 /etc/apt/keyrings

    if [ ! -s "${KEYRING}" ]; then
        change "Downloading the GitHub CLI signing key..."
        sudo curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o "${KEYRING}"
        sudo chmod a+r "${KEYRING}"
    fi

    if [ ! -f "${SOURCES_LIST}" ] || ! grep -qxF "${REPO_LINE}" "${SOURCES_LIST}"; then
        change "Registering the GitHub CLI apt repository..."
        echo "${REPO_LINE}" | sudo tee "${SOURCES_LIST}" >/dev/null
    fi

    sudo apt update
    sudo apt install -y gh
fi

if ! gh auth status >/dev/null 2>&1; then
    change "Authenticating gh - this generates an OAuth token, which is what"
    change "gh itself uses for its own commands (gh pr create, gh issue view,"
    change "gh api, etc) - completely separate from the SSH key below."
    announce_browser_step
    gh auth login --hostname github.com --git-protocol ssh --web \
        --skip-ssh-key --scopes admin:public_key
elif ! has_scope admin:public_key; then
    warn "gh is authenticated but missing the admin:public_key scope"
    warn "needed to upload your SSH key below - requesting it now."
    announce_browser_step
    gh auth refresh --hostname github.com --scopes admin:public_key
else
    ok "gh already authenticated — nothing to do."
fi

SSH_KEY="${HOME}/.ssh/id_ed25519"
if [ -f "${SSH_KEY}.pub" ]; then
    KEY_TITLE="$(cut -d' ' -f3- "${SSH_KEY}.pub")"
    gh ssh-key add "${SSH_KEY}.pub" --title "${KEY_TITLE}"

    # Verified live, not just asserted - a stale "this should work" claim
    # is worse than no claim at all. ssh -T always exits 1 even on success
    # (GitHub refuses shell access on purpose) - under this script's
    # pipefail that would poison a piped exit check regardless of whether
    # grep matched, so the output is captured into a variable first and
    # grepped separately instead of piping directly into grep.
    ssh_check="$(ssh -T -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=5 \
        git@github.com 2>&1 || true)"
    if grep -q "successfully authenticated" <<<"${ssh_check}"; then
        ok "Verified: git push/pull over SSH works."
    else
        warn "Couldn't verify SSH just now (network?) - try again:"
        warn "  ssh -T git@github.com"
    fi
fi
