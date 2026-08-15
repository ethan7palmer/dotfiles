#!/usr/bin/env bash
#
# Symlink everything under home/ into $HOME via GNU Stow. home/ is a single
# package that mirrors $HOME directly (home/.gitconfig -> ~/.gitconfig,
# home/.config/nvim -> ~/.config/nvim, etc), so this is one `stow` call.
#
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -d home ]; then
    echo "No home/ package yet — nothing to stow."
    exit 0
fi

# Stow refuses to symlink over a real (non-symlink) file already at the
# target path. Back any such file up first so a non-fresh machine (or a
# re-run after this script partially applied) doesn't fail the whole run.
while IFS= read -r -d '' src; do
    rel="${src#home/}"
    target="${HOME}/${rel}"
    if [ -e "${target}" ] && [ ! -L "${target}" ]; then
        echo "Backing up existing ${target} -> ${target}.pre-stow-backup"
        mv "${target}" "${target}.pre-stow-backup"
    fi
done < <(find home -type f -print0)

stow -v -t "${HOME}" home
