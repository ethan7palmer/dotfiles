#!/usr/bin/env bash
#
# Entrypoint for provisioning this machine.
#
#   Phase 1 — interactive pre-flight (summary + explicit confirmation)
#   Phase 2 — unattended execution of scripts/*.sh in numeric order
#   Phase 3 — reference: what to know / do, printed every run (not just the
#             first) so it's easy to glance at again later
#
set -euo pipefail

cd "$(dirname "$0")"

# ---------------------------------------------------------------------------
# Output styling — only when stdout is an interactive terminal that supports
# color, so redirecting output to a log file stays plain, readable text.
# ---------------------------------------------------------------------------

if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    BOLD="$(tput bold)"
    RESET="$(tput sgr0)"
    CYAN="$(tput setaf 6)"
    GREEN="$(tput setaf 2)"
else
    BOLD="" RESET="" CYAN="" GREEN=""
fi

phase() {
    echo
    echo "${BOLD}${GREEN}════════════════════════════════════════════════════════${RESET}"
    echo "${BOLD}${GREEN}  $1${RESET}"
    echo "${BOLD}${GREEN}════════════════════════════════════════════════════════${RESET}"
}

section() {
    echo
    echo "${BOLD}${CYAN}-- $1${RESET}"
}

# ---------------------------------------------------------------------------
# Phase 1 — interactive pre-flight
# ---------------------------------------------------------------------------

phase "Phase 1/3 — Pre-flight"

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

section "Git identity"
echo "This is the author name and email attached to every commit made on"
echo "this machine (visible in git log, GitHub commit history, blame, etc)."
DOTFILES_GIT_NAME="$(prompt_with_default "Git user.name" "$(current_git_value user.name)")"
echo
echo "For commits to be linked to your GitHub profile (and count toward its"
echo "contribution graph), this must be an email added to your GitHub"
echo "account under Settings -> Emails — it doesn't have to be your primary"
echo "one, and GitHub's private noreply address works too."
DOTFILES_GIT_EMAIL="$(prompt_with_default "Git user.email" "$(current_git_value user.email)")"

section "SSH key comment"
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

echo
echo "${BOLD}This will install the following on this machine:${RESET}"

section "Prerequisites (apt)"
echo "curl, wget, stow, gnupg, ca-certificates, software-properties-common, jq"
echo "— needed by the remaining scripts, to add third-party apt repos, and"
echo "(jq) to parse JSON in the Claude Code status line."

section "Kitty (apt)"
echo "Terminal emulator."

section "Hack Nerd Font Mono (Nerd Fonts' official GitHub releases)"
echo "No apt package exists for it. Installed to ~/.local/share/fonts (no"
echo "sudo); used by kitty.conf's font_family."

section "Google Chrome (apt, via Google's official signed repository)"
echo "Adds Google's signing key to /etc/apt/keyrings, registers the stable"
echo "channel in /etc/apt/sources.list.d, then installs google-chrome-stable."

section "zsh (apt) + zinit"
echo "Makes zsh the default shell (via chsh) and clones zinit to"
echo "~/.local/share/zinit/zinit.git as its plugin manager."

section "Starship (apt)"
echo "Cross-shell prompt, wired into both .bashrc and .zshrc (falls back to"
echo "the plain colored prompt already in each if starship isn't installed)."

section "Git identity"
echo "user.name \"${DOTFILES_GIT_NAME}\" / user.email \"${DOTFILES_GIT_EMAIL}\""
echo "written to ~/.gitconfig.local (untracked, never committed)."

section "SSH key"
echo "~/.ssh/id_ed25519 generated if missing; comment set to"
echo "\"${DOTFILES_SSH_COMMENT}\"."

section "Claude Code (apt, via Anthropic's signed repository)"
echo "Adds the Claude Code signing key to /etc/apt/keyrings, registers the"
echo "stable channel in /etc/apt/sources.list.d, then installs \`claude-code\`."
echo "Falls back to the official install script only if apt cannot install it."

section "Docker (apt, via Docker's official signed repository)"
echo "Adds Docker's signing key to /etc/apt/keyrings, registers the stable"
echo "channel in /etc/apt/sources.list.d, then installs docker-ce docker-ce-cli"
echo "containerd.io docker-buildx-plugin docker-compose-plugin. Adds"
echo "${USER} to the docker group if not already a member."

section "herdr (official installer)"
echo "Installs to ~/.local/bin via curl -fsSL https://herdr.dev/install.sh | sh,"
echo "then runs \`herdr integration install claude\` so herdr's sidebar gets"
echo "native state-awareness for Claude Code sessions (this updates"
echo "~/.claude/settings.json with hook entries)."

section "Stow symlinks"
echo "Everything under home/ symlinked into \$HOME (e.g. home/.gitconfig ->"
echo "~/.gitconfig), backing up any real file already at that path first."
echo

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

phase "Phase 2/3 — Installing"

for script in scripts/*.sh; do
    echo
    echo "${BOLD}${CYAN}==> ${script}${RESET}"
    bash "${script}"
done

# ---------------------------------------------------------------------------
# Phase 3 — reference report
#
# Printed every run, not just when something changed — this is a reference
# checklist you can glance at again later, not just a diff of what's new.
# ---------------------------------------------------------------------------

phase "Phase 3/3 — What to know"

case "$(getent passwd "${USER}" | cut -d: -f7)" in
    */zsh)
        section "Shell"
        echo "Default shell is zsh. If you just switched to it, open a new"
        echo "terminal/login session for it to take effect — chsh doesn't"
        echo "affect a shell that's already running."
        ;;
esac

if command -v starship >/dev/null 2>&1; then
    section "Prompt"
    echo "Starship is installed. If you just installed it, open a new"
    echo "terminal (or run \`exec \$SHELL\`) for its prompt to take effect —"
    echo "the current shell already loaded .bashrc/.zshrc before starship"
    echo "existed."
fi

section "Claude Code"
if command -v claude >/dev/null 2>&1; then
    echo "If you haven't already, run \`claude\` and log in when prompted."
    echo "Claude Code needs a Pro, Max, Team, Enterprise, or Console account."
else
    echo "\`claude\` is not on your PATH in this shell. If it was installed"
    echo "via the official install script it lives in ~/.local/bin — open a"
    echo "new shell, or add that directory to your PATH."
fi

if id -nG "${USER}" 2>/dev/null | grep -qw docker; then
    section "Docker"
    echo "You're in the docker group. If you were just added, log out and"
    echo "back in (or reboot) — group membership is read at login, not"
    echo "live, so until then \`docker\` commands fail with a permissions"
    echo "error (Cannot connect to the Docker daemon...permission denied)."
fi

if [ -f "${SSH_KEY}.pub" ]; then
    section "SSH key"
    echo "$(cat "${SSH_KEY}.pub")"
    echo
    echo "If you haven't already, add it at github.com under Settings ->"
    echo "SSH and GPG keys (paste the line above into \"Key\", give it a"
    echo "title), then verify it with:"
    echo
    echo "  ssh -T git@github.com"
    echo
    echo "That trusts GitHub's host fingerprint on first connect (type"
    echo "\"yes\" when asked) and confirms the key works — look for"
    echo "\"Hi <username>! You've successfully authenticated...\" in the"
    echo "output."
fi

# The Day 0 clone in this README uses https://, so pushing back to this repo
# will fail until the remote is switched to SSH — install.sh only sets up an
# SSH key, not HTTPS credentials.
origin_url="$(git config --get remote.origin.url 2>/dev/null || true)"
if [ -f "${SSH_KEY}.pub" ] && [ "${origin_url#https://github.com/}" != "${origin_url}" ]; then
    ssh_url="git@github.com:${origin_url#https://github.com/}"
    case "${ssh_url}" in
        *.git) ;;
        *) ssh_url="${ssh_url}.git" ;;
    esac
    section "This repo's remote"
    echo "Set to HTTPS, not SSH. Pushing changes back to this dotfiles repo"
    echo "will fail with HTTPS (no credentials are set up for that). Run"
    echo "this to switch it to the SSH key above instead:"
    echo
    echo "  git remote set-url origin ${ssh_url}"
fi

section "Status"
echo "The rest of this repo is not built yet. See \"Status\" in README.md"
echo "for the scripts still to be written."
echo
