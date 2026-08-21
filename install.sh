#!/usr/bin/env bash
#
# Entrypoint for provisioning this machine.
#
#   Phase 1 — interactive pre-flight (summary + explicit confirmation)
#   Phase 2 — unattended execution of scripts/*.sh in numeric order, except
#             16-gh.sh's one-time gh auth login browser approval - the only
#             script here that can't be made fully unattended
#   Phase 3 — reference: what to know / do, printed every run (not just the
#             first) so it's easy to glance at again later
#
set -euo pipefail

cd "$(dirname "$0")"
source lib/stages.sh

source lib/colors.sh

# Two header tiers, two colors: BLUE for the 3 top-level phase banners,
# ORANGE for every "-- Section" underneath one, so scrollback makes the
# hierarchy obvious without having to read the box-drawing characters.
phase() {
    echo
    echo "${BLUE}════════════════════════════════════════════════════════${RESET}"
    echo "${BLUE}  $1${RESET}"
    echo "${BLUE}════════════════════════════════════════════════════════${RESET}"
}

section() {
    echo
    echo "${ORANGE}-- $1${RESET}"
}

# A highlighted, single-line call to action - Phase 3 uses this so the one
# thing you actually need to go do never gets lost in surrounding prose.
# Magenta because it means something different from warn()'s yellow: this
# isn't a heads-up, it's a to-do only you (not the script) can finish.
action() {
    echo "${BOLD}${MAGENTA}-> $1${RESET}"
}

# ---------------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------------

FORCE_IDENTITY_PROMPT=false
INTERACTIVE_SKIP=false
declare -A SKIP=()

for arg in "$@"; do
    case "${arg}" in
        -h | --help)
            cat <<EOF
${BOLD}Usage:${RESET} ./install.sh [OPTIONS]

Provisions this machine: prereqs, Kitty, Hack Nerd Font, Chrome, zsh,
Starship, git identity, an SSH key, vim, Docker, Claude Code, herdr, Handy,
the GitHub CLI, tmux, then symlinks home/ into \$HOME via GNU Stow. Safe to
re-run any time.

${BOLD}Options:${RESET}
  --update-identity   Re-prompt for git user.name/user.email and the SSH
                       key comment even if they're already set. Normally
                       these are only asked for once and reused silently
                       on every later run.
  --skip=STAGE,...    Skip these stages (comma-separated). Stage ids are
                       the scripts/ filenames with the numeric prefix
                       stripped, e.g. handy, docker, gnome-settings.
                       Current stages: $(all_stage_ids scripts | paste -sd, -)
  --skip               Same, but prompts with a numbered checklist instead
                       of taking stage ids on the command line.
  -h, --help           Show this help and exit.
EOF
            exit 0
            ;;
        --update-identity)
            FORCE_IDENTITY_PROMPT=true
            ;;
        --skip=*)
            raw="${arg#--skip=}"
            valid="$(all_stage_ids scripts)"
            for id in ${raw//,/ }; do
                if ! grep -qx "${id}" <<<"${valid}"; then
                    err "Unknown stage for --skip: ${id}"
                    echo "Valid stages: $(echo "${valid}" | paste -sd, -)" >&2
                    exit 1
                fi
                SKIP["${id}"]=true
            done
            ;;
        --skip)
            INTERACTIVE_SKIP=true
            ;;
        *)
            err "Unknown option: ${arg}"
            echo "Run './install.sh --help' for usage." >&2
            exit 1
            ;;
    esac
done

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
        warn "This can't be empty."
    done
}

DOTFILES_GIT_NAME=""
DOTFILES_GIT_EMAIL=""
if ! skipped git-identity; then
    section "Git identity"
    current_git_name="$(current_git_value user.name)"
    current_git_email="$(current_git_value user.email)"
    if [ -n "${current_git_name}" ] && [ -n "${current_git_email}" ] && [ "${FORCE_IDENTITY_PROMPT}" = false ]; then
        value "Using existing identity: ${current_git_name} <${current_git_email}>"
        echo "(run with --update-identity to change)"
        DOTFILES_GIT_NAME="${current_git_name}"
        DOTFILES_GIT_EMAIL="${current_git_email}"
    else
        echo "This is the author name and email attached to every commit made on"
        echo "this machine (visible in git log, GitHub commit history, blame, etc)."
        DOTFILES_GIT_NAME="$(prompt_with_default "Git user.name" "${current_git_name}")"
        echo
        echo "For commits to be linked to your GitHub profile (and count toward its"
        echo "contribution graph), this must be an email added to your GitHub"
        echo "account under Settings -> Emails — it doesn't have to be your primary"
        echo "one, and GitHub's private noreply address works too."
        DOTFILES_GIT_EMAIL="$(prompt_with_default "Git user.email" "${current_git_email}")"
    fi
fi

DOTFILES_SSH_COMMENT=""
if ! skipped ssh-key; then
    section "SSH key comment"
    if [ -f "${SSH_KEY}.pub" ]; then
        current_comment="$(cut -d' ' -f3- "${SSH_KEY}.pub")"
        if [ "${FORCE_IDENTITY_PROMPT}" = false ]; then
            value "Using existing comment: ${current_comment}"
            echo "(run with --update-identity to change — this only relabels the"
            echo "key, it does NOT regenerate it)"
            DOTFILES_SSH_COMMENT="${current_comment}"
        else
            echo "A label attached to the SSH key so it's identifiable wherever"
            echo "it's listed later — e.g. on GitHub's (or any other service's)"
            echo "SSH keys page, or in \`ssh-add -l\`."
            echo "A key already exists at ${SSH_KEY}. Changing this only relabels it"
            echo "(ssh-keygen -c) — it does NOT regenerate the key, which would"
            echo "invalidate anything already trusting the old public key."
            DOTFILES_SSH_COMMENT="$(prompt_with_default "SSH key comment" "${current_comment}")"
        fi
    else
        echo "A label attached to the SSH key so it's identifiable wherever it's"
        echo "listed later — e.g. on GitHub's (or any other service's) SSH keys"
        echo "page, or in \`ssh-add -l\`."
        echo "No SSH key yet — one will be generated at ${SSH_KEY}."
        DOTFILES_SSH_COMMENT="$(prompt_with_default "SSH key comment" "$(id -un)@$(hostname)")"
    fi
fi
echo

export DOTFILES_GIT_NAME DOTFILES_GIT_EMAIL DOTFILES_SSH_COMMENT

if [ "${INTERACTIVE_SKIP}" = true ]; then
    section "Stages to skip"
    echo "Enter the numbers of any stages to skip (space or comma separated),"
    echo "or press Enter to skip none:"
    prompt_skip_picker scripts
fi

echo
echo "${BOLD}This will install the following on this machine:${RESET}"

if [ "${#SKIP[@]}" -gt 0 ]; then
    section "Skipping"
    for id in $(all_stage_ids scripts); do
        skipped "${id}" && echo "  - ${id}"
    done
fi

if ! skipped prereqs; then
    section "Prerequisites (apt)"
    echo "curl, wget, stow, gnupg, ca-certificates, software-properties-common, jq,"
    echo "ripgrep, fd-find — needed by the remaining scripts, to add third-party"
    echo "apt repos, (jq) to parse JSON in the Claude Code status line, and"
    echo "(ripgrep/fd, symlinked as fd) by Neovim's fuzzy pickers."
fi

if ! skipped kitty; then
    section "Kitty (apt)"
    echo "Terminal emulator."
fi

if ! skipped nerd-font; then
    section "Hack Nerd Font Mono (Nerd Fonts' official GitHub releases)"
    echo "No apt package exists for it. Installed to ~/.local/share/fonts (no"
    echo "sudo); used by kitty.conf's font_family."
fi

if ! skipped chrome; then
    section "Google Chrome (apt, via Google's official signed repository)"
    echo "Adds Google's signing key to /etc/apt/keyrings, registers the stable"
    echo "channel in /etc/apt/sources.list.d, then installs google-chrome-stable."
fi

if ! skipped zsh; then
    section "zsh (apt) + zinit"
    echo "Makes zsh the default shell (via chsh) and clones zinit to"
    echo "~/.local/share/zinit/zinit.git as its plugin manager."
fi

if ! skipped starship; then
    section "Starship (apt)"
    echo "Cross-shell prompt, wired into both .bashrc and .zshrc (falls back to"
    echo "the plain colored prompt already in each if starship isn't installed)."
fi

if ! skipped git-identity; then
    section "Git identity"
    echo "user.name \"${DOTFILES_GIT_NAME}\" / user.email \"${DOTFILES_GIT_EMAIL}\""
    echo "written to ~/.gitconfig.local (untracked, never committed)."
fi

if ! skipped ssh-key; then
    section "SSH key"
    echo "~/.ssh/id_ed25519 generated if missing; comment set to"
    echo "\"${DOTFILES_SSH_COMMENT}\"."
fi

if ! skipped vim; then
    section "vim (apt)"
    echo "No configuration — just a better default than vi for occasional use."
fi

if ! skipped neovim; then
    section "Neovim (apt) + config"
    echo "lazy.nvim-managed: which-key, oil.nvim + snacks.nvim (fuzzy picker,"
    echo "needs ripgrep for grep), neogit + gitsigns, rose-pine (moon) theme."
    echo "Plugins install themselves the first time nvim runs (needs network"
    echo "once)."
fi

if ! skipped claude-code; then
    section "Claude Code (apt, via Anthropic's signed repository)"
    echo "Adds the Claude Code signing key to /etc/apt/keyrings, registers the"
    echo "stable channel in /etc/apt/sources.list.d, then installs \`claude-code\`."
fi

if ! skipped docker; then
    section "Docker (apt, via Docker's official signed repository)"
    echo "Adds Docker's signing key to /etc/apt/keyrings, registers the stable"
    echo "channel in /etc/apt/sources.list.d, then installs docker-ce docker-ce-cli"
    echo "containerd.io docker-buildx-plugin docker-compose-plugin. Adds"
    echo "${USER} to the docker group if not already a member."
fi

if ! skipped stow-symlinks; then
    section "Stow symlinks"
    echo "Everything under home/ symlinked into \$HOME (e.g. home/.gitconfig ->"
    echo "~/.gitconfig), backing up any real file already at that path first."
fi

if ! skipped gnome-settings; then
    section "GNOME/Ubuntu Dock settings (gsettings, individual keys)"
    echo "Chrome as default browser, 24-hour clock, mouse with no acceleration,"
    echo "screen never blanks from inactivity, dock moved to the"
    echo "bottom/shrunk/auto-hidden showing only Chrome/Kitty/Files (no drives,"
    echo "trash, or unpinned running apps), no Home icon on the desktop,"
    echo "background set to this repo's wallpaper.jpg. Each setting is an"
    echo "individual, reversible gsettings call - never a wholesale dconf load,"
    echo "which can silently break the shell."
fi

if ! skipped herdr; then
    section "herdr (official installer)"
    echo "Installs to ~/.local/bin via curl -fsSL https://herdr.dev/install.sh | sh,"
    echo "then runs \`herdr integration install claude\` so herdr's sidebar gets"
    echo "native state-awareness for Claude Code sessions. Runs after the stow"
    echo "step on purpose, so it always writes into the already-symlinked (and"
    echo "so machine-portable) ~/.claude/settings.json last."
fi

if ! skipped handy; then
    section "Handy (signed GitHub release) + ydotool (apt)"
    echo "Local-only speech-to-text. Handy's .deb is verified with minisign"
    echo "against its signing key before install. Also installs ydotool (the"
    echo "Wayland text-injection backend Handy needs) and adds ${USER} to the"
    echo "input group, enables the ydotool.service user service, registers a"
    echo "GNOME custom shortcut (Ctrl+Alt+Space -> toggle transcription, since"
    echo "Handy's own in-app shortcut doesn't work under Wayland), downloads"
    echo "its default model (checksum-verified), and turns on quiet (20%)"
    echo "audio feedback + launch-at-login without popping its window in"
    echo "Handy's own settings so there's no first-run setup to click through"
    echo "and no window to dismiss every login, and leaves Handy running when"
    echo "it's done."
fi

if ! skipped gh; then
    section "GitHub CLI (GitHub's own apt repo)"
    echo "Then \`gh auth login\` - the one interactive step in this whole"
    echo "install. You'll approve a one-time code in a browser, which gets"
    echo "gh an OAuth token - used only for gh's own commands (gh pr create,"
    echo "gh api, etc), completely separate from the SSH key above. gh then"
    echo "uploads that SSH key to your GitHub account automatically (no"
    echo "extra prompt) - that upload is what git itself actually uses for"
    echo "any git@github.com:... remote. Plain git over https:// stays NOT"
    echo "set up (no credential helper) - only SSH remotes and gh's own"
    echo "commands will work after this; \`gh auth setup-git\` adds that, if"
    echo "you ever need it."
fi

if ! skipped tmux; then
    section "tmux (apt)"
    echo "Terminal multiplexer, independent of herdr - skip either one, or"
    echo "install both. Its keybindings (~/.config/tmux/tmux.conf) are"
    echo "deliberately made to match herdr's, so switching between the two"
    echo "doesn't mean re-learning muscle memory."
fi
echo

reply=""
read -r -p "Continue? [Y/n] " reply || true
case "$(printf '%s' "$reply" | tr '[:upper:]' '[:lower:]')" in
    n | no)
        echo "Aborted, no changes made."
        exit 0
        ;;
    *) ;;
esac

# ---------------------------------------------------------------------------
# Phase 2 — unattended execution
# ---------------------------------------------------------------------------

phase "Phase 2/3 — Installing"

for script in scripts/*.sh; do
    skipped "$(stage_id "${script}")" && continue
    echo
    echo "${ORANGE}==> ${script}${RESET}"
    bash "${script}"
done

# ---------------------------------------------------------------------------
# Phase 3 — reference report
#
# Printed every run, not just when something changed — this is a reference
# checklist you can glance at again later, not just a diff of what's new.
# ---------------------------------------------------------------------------

phase "Phase 3/3 — What to know"

if ! skipped zsh; then
    case "$(getent passwd "${USER}" | cut -d: -f7)" in
        */zsh)
            section "Shell"
            action "Open a new terminal - this one won't pick up zsh, or"
            action "anything just changed in .zshrc/.bash_aliases (aliases,"
            action "functions like herdr-keys/tmux-keys, etc)."
            ;;
    esac
fi

if ! skipped starship && command -v starship >/dev/null 2>&1; then
    section "Prompt"
    action "Open a new terminal (or run \`exec \$SHELL\`) for Starship to apply."
fi

if ! skipped claude-code; then
    section "Claude Code"
    action "Run \`claude\` and log in (Pro/Max/Team/Enterprise/Console account)."
fi

if ! skipped docker && id -nG "${USER}" 2>/dev/null | grep -qw docker; then
    section "Docker"
    action "Log out and back in (or reboot) for docker group access to apply."
fi

if ! skipped handy && command -v handy >/dev/null 2>&1; then
    section "Handy"
    echo "Keybind: Ctrl+Alt+Space to toggle transcription."
    if id -nG "${USER}" 2>/dev/null | grep -qw input; then
        action "REBOOT - the input-group permission ydotool needs won't"
        action "survive just logging out, so the keybind can't type yet."
    fi
fi

# scripts/16-gh.sh already handles auth (including the admin:public_key
# scope) and verifies the SSH upload live, right as it happens - if that
# ran this run, there's nothing left to check here. The only gap is if
# the gh stage was skipped entirely, in which case the key was never
# uploaded anywhere and still needs to go in by hand.
if ! skipped ssh-key && skipped gh && [ -f "${SSH_KEY}.pub" ]; then
    section "SSH key"
    action "Add this key at github.com -> Settings -> SSH and GPG keys:"
    echo
    cat "${SSH_KEY}.pub"
fi

# The Day 0 clone in this README uses https://, so pushing back to this repo
# will fail until the remote is switched to SSH — install.sh only sets up an
# SSH key, not HTTPS credentials.
origin_url="$(git config --get remote.origin.url 2>/dev/null || true)"
if ! skipped ssh-key && [ -f "${SSH_KEY}.pub" ] && [ "${origin_url#https://github.com/}" != "${origin_url}" ]; then
    ssh_url="git@github.com:${origin_url#https://github.com/}"
    case "${ssh_url}" in
        *.git) ;;
        *) ssh_url="${ssh_url}.git" ;;
    esac
    section "This repo's remote"
    action "Run: git remote set-url origin ${ssh_url}"
fi

echo
