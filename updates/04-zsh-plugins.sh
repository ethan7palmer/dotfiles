#!/usr/bin/env bash
#
# zinit (the plugin manager scripts/04-zsh.sh clones) and the plugins it
# manages (declared in home/.zshrc: zsh-autosuggestions, zsh-syntax-
# highlighting) update themselves through zinit's own commands - there's
# no apt package or standalone binary for either.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"
if [ ! -d "${ZINIT_HOME}" ]; then
    ok "zinit isn't installed — nothing to do."
    exit 0
fi

# -i forces zsh to source .zshrc (which bootstraps zinit) even without a
# TTY attached; there's no non-interactive form of these two commands.
zsh -ic 'zinit self-update && zinit update --all'
