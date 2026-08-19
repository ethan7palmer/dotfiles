#!/usr/bin/env bash
#
# Install zsh, make it the default shell, and install zinit (plugin
# manager). The actual plugin list lives in the stowed .zshrc — this script
# only ensures zinit itself is present so that file's zinit bootstrap works.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

if command -v zsh >/dev/null 2>&1; then
    ok "zsh already installed — nothing to do."
else
    change "Installing zsh..."
    sudo apt update
    sudo apt install -y zsh
fi

ZSH_PATH="$(command -v zsh)"
# $SHELL is set once when the terminal session starts and never updates
# mid-session, even after chsh rewrites /etc/passwd — so re-runs in the same
# terminal would see the stale pre-chsh value here and re-prompt for sudo
# every time. Read the actual current passwd entry instead.
CURRENT_SHELL="$(getent passwd "${USER}" | cut -d: -f7)"
if [ "${CURRENT_SHELL}" = "${ZSH_PATH}" ]; then
    ok "Default shell is already zsh — nothing to do."
else
    change "Changing default shell to ${ZSH_PATH}..."
    # Run as root so this doesn't prompt for the user's own password.
    sudo chsh -s "${ZSH_PATH}" "${USER}"
fi

ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"
if [ -d "${ZINIT_HOME}" ]; then
    ok "zinit already installed — nothing to do."
else
    change "Installing zinit..."
    mkdir -p "$(dirname "${ZINIT_HOME}")"
    git clone https://github.com/zdharma-continuum/zinit.git "${ZINIT_HOME}"
fi
