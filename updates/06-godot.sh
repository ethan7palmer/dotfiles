#!/usr/bin/env bash
#
# Godot has no apt repo behind it (see scripts/23-godot.sh), so apt
# upgrades never see new versions - re-run the same install script, which
# already resolves the newest 4.x stable release and no-ops if that's
# what's already installed.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

if [ ! -x "${HOME}/.local/bin/godot" ]; then
    ok "Godot isn't installed — nothing to do."
    exit 0
fi

"$(dirname "$0")/../scripts/23-godot.sh"
