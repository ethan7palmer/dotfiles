#!/usr/bin/env bash
#
# Entrypoint for provisioning this machine.
#
#   Phase 1 — interactive pre-flight (summary + explicit confirmation)
#   Phase 2 — unattended execution of scripts/*.sh in numeric order
#   Phase 3 — final report of what still needs a human
#
set -euo pipefail

cd "$(dirname "$0")"

# ---------------------------------------------------------------------------
# Phase 1 — interactive pre-flight
# ---------------------------------------------------------------------------

GITCONFIG_LOCAL="${HOME}/.gitconfig.local"
SSH_KEY="${HOME}/.ssh/id_ed25519"

current_git_value() {
    git config --file "${GITCONFIG_LOCAL}" "$1" 2>/dev/null || true
}

# Prompts for a value, pre-filling $2 as the default if non-empty (a value
# from a previous run). Enter alone keeps the default; anything typed
# overrides it. Loops until non-empty when there's no default (first run).
prompt_with_default() {
    local prompt_text="$1" default_value="$2" reply
    while true; do
        if [ -n "${default_value}" ]; then
            read -r -p "${prompt_text} [${default_value}]: " reply || true
            [ -z "${reply}" ] && reply="${default_value}"
        else
            read -r -p "${prompt_text}: " reply || true
        fi
        if [ -n "${reply}" ]; then
            printf '%s' "${reply}"
            return
        fi
        echo "This can't be empty." >&2
    done
}

echo "== Git identity =="
echo "This is the author name and email attached to every commit made on"
echo "this machine (visible in git log, GitHub commit history, blame, etc)."
DOTFILES_GIT_NAME="$(prompt_with_default "Git user.name" "$(current_git_value user.name)")"
echo
echo "For commits to be linked to your GitHub profile (and count toward its"
echo "contribution graph), this must be an email added to your GitHub"
echo "account under Settings -> Emails — it doesn't have to be your primary"
echo "one, and GitHub's private noreply address works too."
DOTFILES_GIT_EMAIL="$(prompt_with_default "Git user.email" "$(current_git_value user.email)")"
echo

echo "== SSH key comment =="
echo "A label attached to the SSH key so it's identifiable wherever it's"
echo "listed later — e.g. on GitHub's (or any other service's) SSH keys"
echo "page, or in \`ssh-add -l\`."
if [ -f "${SSH_KEY}.pub" ]; then
    current_comment="$(cut -d' ' -f3- "${SSH_KEY}.pub")"
    echo "A key already exists at ${SSH_KEY}. Changing this only relabels it"
    echo "(ssh-keygen -c) — it does NOT regenerate the key, which would"
    echo "invalidate anything already trusting the old public key."
    DOTFILES_SSH_COMMENT="$(prompt_with_default "SSH key comment" "${current_comment}")"
else
    echo "No SSH key yet — one will be generated at ${SSH_KEY}."
    DOTFILES_SSH_COMMENT="$(prompt_with_default "SSH key comment" "$(id -un)@$(hostname)")"
fi
echo

export DOTFILES_GIT_NAME DOTFILES_GIT_EMAIL DOTFILES_SSH_COMMENT

cat <<SUMMARY
This will install the following on this machine:

  Prerequisites (apt)
    curl, wget, stow, gnupg, ca-certificates, software-properties-common, jq
    — needed by the remaining scripts, to add third-party apt repos, and
    (jq) to parse JSON in the Claude Code status line.

  Kitty (apt)
    Terminal emulator.

  Google Chrome (apt, via Google's official signed repository)
    Adds Google's signing key to /etc/apt/keyrings, registers the stable
    channel in /etc/apt/sources.list.d, then installs google-chrome-stable.

  Git identity
    user.name "${DOTFILES_GIT_NAME}" / user.email "${DOTFILES_GIT_EMAIL}"
    written to ~/.gitconfig.local (untracked, never committed).

  SSH key
    ~/.ssh/id_ed25519 generated if missing; comment set to
    "${DOTFILES_SSH_COMMENT}".

  Claude Code (apt, via Anthropic's signed repository)
    Adds the Claude Code signing key to /etc/apt/keyrings, registers the
    stable channel in /etc/apt/sources.list.d, then installs \`claude-code\`.
    Falls back to the official install script only if apt cannot install it.

  Stow symlinks
    Everything under home/ symlinked into \$HOME (e.g. home/.gitconfig ->
    ~/.gitconfig), backing up any real file already at that path first.

SUMMARY

reply=""
read -r -p "Continue? [y/N] " reply || true
case "$(printf '%s' "$reply" | tr '[:upper:]' '[:lower:]')" in
    y | yes) ;;
    *)
        echo "Aborted, no changes made."
        exit 0
        ;;
esac

# ---------------------------------------------------------------------------
# Phase 2 — unattended execution
# ---------------------------------------------------------------------------

# Recorded before anything runs, so the Phase 3 report can describe what
# actually changed rather than just what the end state looks like.
claude_was_present=false
if command -v claude >/dev/null 2>&1; then
    claude_was_present=true
fi

ssh_key_was_present=false
if [ -f "${SSH_KEY}.pub" ]; then
    ssh_key_was_present=true
fi

for script in scripts/*.sh; do
    echo
    echo "==> Running ${script}"
    bash "${script}"
done

# ---------------------------------------------------------------------------
# Phase 3 — final report
# ---------------------------------------------------------------------------

echo
echo "==> Done. What to do next:"
echo

if [ "${claude_was_present}" = false ]; then
    cat <<'NEXT'
  * Authenticate Claude Code.
    The first time you run `claude` it opens a browser to log in. This is
    expected — nothing here scripts or stores credentials. Claude Code needs
    a Pro, Max, Team, Enterprise, or Console account.

NEXT
fi

if ! command -v claude >/dev/null 2>&1; then
    cat <<'NEXT'
  * `claude` is not on your PATH in this shell.
    If it was just installed via the official install script it lives in
    ~/.local/bin — open a new shell, or add that directory to your PATH.

NEXT
fi

if [ "${ssh_key_was_present}" = false ] && [ -f "${SSH_KEY}.pub" ]; then
    cat <<NEXT
  * Add your new SSH key to GitHub.
    $(cat "${SSH_KEY}.pub")

    Copy and paste the line above into the "Key" field at github.com under
    Settings -> SSH and GPG keys (you'll also need to give it a title), so
    you can push/pull over SSH and clone private repos.

    Then run: ssh -T git@github.com
    That trusts GitHub's host fingerprint on first connect (type "yes" when
    asked) and confirms the key works — look for "Hi <username>! You've
    successfully authenticated..." in the output.

NEXT
fi

cat <<'NEXT'
  * The rest of this repo is not built yet.
    See "Status" in README.md for the scripts still to be written.

NEXT
