#!/usr/bin/env bash
#
# Generate an SSH key if one doesn't exist yet, or relabel its comment
# (never regenerate) if the pre-flight comment differs from the current one.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

: "${DOTFILES_SSH_COMMENT:?DOTFILES_SSH_COMMENT not set — run via install.sh}"

SSH_KEY="${HOME}/.ssh/id_ed25519"

if [ ! -f "${SSH_KEY}" ]; then
    change "Generating SSH key at ${SSH_KEY}..."
    mkdir -p "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"
    ssh-keygen -t ed25519 -C "${DOTFILES_SSH_COMMENT}" -f "${SSH_KEY}" -N ""
else
    current_comment="$(cut -d' ' -f3- "${SSH_KEY}.pub")"
    if [ "${current_comment}" != "${DOTFILES_SSH_COMMENT}" ]; then
        change "Relabeling existing SSH key comment..."
        ssh-keygen -c -C "${DOTFILES_SSH_COMMENT}" -f "${SSH_KEY}"
    else
        ok "SSH key already exists with the requested comment — nothing to do."
    fi
fi
