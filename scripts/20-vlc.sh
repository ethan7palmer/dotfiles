#!/usr/bin/env bash
#
# Install VLC via apt. Plays WAV/MP3/MP4 and just about everything else out
# of the box - no separate codec packages needed.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

if command -v vlc >/dev/null 2>&1; then
    ok "vlc already installed — nothing to do."
else
    change "Installing vlc..."
    sudo apt update
    sudo apt install -y vlc
fi
