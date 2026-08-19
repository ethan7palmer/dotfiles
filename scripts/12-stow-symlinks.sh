#!/usr/bin/env bash
#
# Symlink everything under home/ into $HOME via GNU Stow. home/ is a single
# package that mirrors $HOME directly (home/.gitconfig -> ~/.gitconfig,
# home/.config/nvim -> ~/.config/nvim, etc), so this is one `stow` call.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

cd "$(dirname "$0")/.."

if [ ! -d home ]; then
    ok "No home/ package yet — nothing to stow."
    exit 0
fi

# Stow refuses to symlink over a real file already at the target path. Back
# any such file up first so a non-fresh machine doesn't fail the whole run.
#
# Compare resolved real paths rather than checking `-L` on the target: once
# an ancestor directory of the target is itself a whole-directory symlink
# into home/ (which Stow does whenever the parent didn't previously exist,
# e.g. a from-scratch ~/.claude), the leaf file reached through it is not
# itself a symlink, but it and the source file are the same inode. Treating
# that as "a real file blocking the target" and mv-ing it would rename the
# tracked source file in the repo out from under itself.
while IFS= read -r -d '' src; do
    rel="${src#home/}"
    target="${HOME}/${rel}"
    if [ -e "${target}" ] && [ "$(readlink -f "${target}")" != "$(readlink -f "${src}")" ]; then
        warn "Backing up existing ${target} -> ${target}.pre-stow-backup"
        mv "${target}" "${target}.pre-stow-backup"
    fi
done < <(find home -type f -print0)

stow -v -t "${HOME}" home
