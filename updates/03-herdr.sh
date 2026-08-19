#!/usr/bin/env bash
#
# herdr has its own self-updater.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

if command -v herdr >/dev/null 2>&1; then
    HERDR_BIN="$(command -v herdr)"
elif [ -x "${HOME}/.local/bin/herdr" ]; then
    HERDR_BIN="${HOME}/.local/bin/herdr"
else
    ok "herdr isn't installed — nothing to do."
    exit 0
fi

# herdr sets this in every session it's managing (e.g. this very Claude
# Code session, if update.sh is being run from inside one) and refuses to
# self-update there - replacing its own binary out from under a session
# it's actively tracking would be self-destructive. Not a real failure,
# so don't let it abort the rest of update.sh - just say why and move on.
if [ -n "${HERDR_ENV:-}" ]; then
    warn "Running inside a herdr session - skipping (herdr refuses to"
    warn "self-update here). Run \`herdr update\` from a terminal herdr"
    warn "isn't managing to update it."
    exit 0
fi

"${HERDR_BIN}" update
