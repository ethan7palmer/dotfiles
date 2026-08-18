#!/usr/bin/env bash
#
# Claude Code is installed one of two ways by scripts/11-claude-code.sh:
# apt (the normal path) or the official install script (fallback only,
# e.g. an unsupported architecture). Covers both from one place rather
# than folding the apt case into updates/01-apt.sh.
#
set -euo pipefail

if dpkg -s claude-code >/dev/null 2>&1; then
    sudo apt update
    sudo apt install --only-upgrade -y claude-code
elif command -v claude >/dev/null 2>&1; then
    claude update
else
    echo "Claude Code isn't installed — nothing to do."
fi
