#!/usr/bin/env bash
#
# Install vim via apt. No configuration — just a better default than vi for
# occasional use. Neovim (the actual daily-driver editor, per EDITOR=nvim in
# .bashrc/.zshrc/git config) is a separate, not-yet-written stage.
#
set -euo pipefail

if command -v vim >/dev/null 2>&1; then
    echo "vim already installed — nothing to do."
else
    echo "Installing vim..."
    sudo apt update
    sudo apt install -y vim
fi
