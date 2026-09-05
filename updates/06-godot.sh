#!/usr/bin/env bash
#
# Godot has no apt repo behind it (see scripts/23-godot.sh), so apt
# upgrades never see new versions - re-run the same install script, which
# already resolves the newest 4.x stable release and no-ops if that's
# what's already installed. Same story for gdtoolkit (pipx, not apt) -
# `pipx upgrade` is that script's re-run-safe equivalent.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

if [ ! -x "${HOME}/.local/bin/godot" ]; then
    ok "Godot isn't installed — nothing to do."
else
    "$(dirname "$0")/../scripts/23-godot.sh"
fi

if command -v gdformat >/dev/null 2>&1; then
    pipx upgrade gdtoolkit
else
    ok "gdtoolkit isn't installed — nothing to do."
fi
