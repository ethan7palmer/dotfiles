#!/usr/bin/env bash
#
# Write the git identity collected in install.sh's pre-flight to the
# untracked ~/.gitconfig.local (included from the tracked home/.gitconfig).
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

: "${DOTFILES_GIT_NAME:?DOTFILES_GIT_NAME not set — run via install.sh}"
: "${DOTFILES_GIT_EMAIL:?DOTFILES_GIT_EMAIL not set — run via install.sh}"

GITCONFIG_LOCAL="${HOME}/.gitconfig.local"

git config --file "${GITCONFIG_LOCAL}" user.name "${DOTFILES_GIT_NAME}"
git config --file "${GITCONFIG_LOCAL}" user.email "${DOTFILES_GIT_EMAIL}"
ok "Wrote git identity to ${GITCONFIG_LOCAL}"
