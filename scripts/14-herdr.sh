#!/usr/bin/env bash
#
# Install herdr via its official installer, then wire up the Claude Code
# integration so herdr's sidebar gets native state-awareness for Claude
# Code sessions.
#
# Docs: https://herdr.dev/docs/install/, https://herdr.dev/docs/integrations/
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

resolve_herdr() {
    if command -v herdr >/dev/null 2>&1; then
        command -v herdr
    elif [ -x "${HOME}/.local/bin/herdr" ]; then
        echo "${HOME}/.local/bin/herdr"
    fi
}

HERDR_BIN="$(resolve_herdr)"

if [ -n "${HERDR_BIN}" ]; then
    ok "herdr already installed at ${HERDR_BIN} — leaving it alone."
else
    change "Installing herdr..."
    curl -fsSL https://herdr.dev/install.sh | sh
    HERDR_BIN="$(resolve_herdr)"
    if [ -z "${HERDR_BIN}" ]; then
        err "herdr was not found after installation."
        exit 1
    fi
fi

# `herdr integration install claude` writes ~/.claude/hooks/herdr-agent-state.sh
# and adds hook entries to ~/.claude/settings.json — check for the hook script
# so re-runs don't redo that.
HERDR_HOOK="${HOME}/.claude/hooks/herdr-agent-state.sh"
if [ -f "${HERDR_HOOK}" ]; then
    ok "herdr Claude Code integration already installed — nothing to do."
else
    change "Installing herdr's Claude Code integration..."
    "${HERDR_BIN}" integration install claude
fi

# herdr doesn't watch config.toml for changes - a running server (i.e.
# this is a re-run, not a fresh install) needs an explicit reload or it
# keeps using whatever it read on last start, silently ignoring anything
# just symlinked into place by the stow step above. A fresh install has
# no server running yet, so there's nothing to reload here - it reads
# the config fresh the first time it starts.
if [ "$("${HERDR_BIN}" status server --json 2>/dev/null | jq -r '.running // false')" = "true" ]; then
    change "Reloading herdr's running config..."
    "${HERDR_BIN}" server reload-config >/dev/null
fi
