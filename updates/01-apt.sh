#!/usr/bin/env bash
#
# Upgrade every apt package this repo installs, scoped to exactly this
# list - never a blanket `apt upgrade`, so a run of update.sh can't reach
# into unrelated packages on the machine. Skips anything not currently
# installed (e.g. a stage left out with install.sh's --skip).
#
# claude-code is deliberately not here - it can also be installed via the
# official script fallback instead of apt, so it's handled entirely by
# updates/02-claude-code.sh, matching how scripts/11-claude-code.sh owns
# both of its install paths too.
#
set -euo pipefail

PACKAGES=(
    curl wget stow gnupg ca-certificates software-properties-common
    jq ripgrep fd-find
    kitty
    google-chrome-stable
    zsh
    starship
    vim
    neovim
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    ydotool
    minisign
)

installed=()
for pkg in "${PACKAGES[@]}"; do
    dpkg -s "${pkg}" >/dev/null 2>&1 && installed+=("${pkg}")
done

if [ ${#installed[@]} -eq 0 ]; then
    echo "None of this repo's apt packages are installed — nothing to do."
    exit 0
fi

sudo apt update
sudo apt install --only-upgrade -y "${installed[@]}"
