#!/usr/bin/env bash
#
# Install herdr via its official installer, then wire up the Claude Code
# integration so herdr's sidebar gets native state-awareness for Claude
# Code sessions.
#
# Docs: https://herdr.dev/docs/install/, https://herdr.dev/docs/integrations/
#
set -euo pipefail

resolve_herdr() {
    if command -v herdr >/dev/null 2>&1; then
        command -v herdr
    elif [ -x "${HOME}/.local/bin/herdr" ]; then
        echo "${HOME}/.local/bin/herdr"
    fi
}

HERDR_BIN="$(resolve_herdr)"

if [ -n "${HERDR_BIN}" ]; then
    echo "herdr already installed at ${HERDR_BIN} — leaving it alone."
else
    echo "Installing herdr..."
    curl -fsSL https://herdr.dev/install.sh | sh
    HERDR_BIN="$(resolve_herdr)"
    if [ -z "${HERDR_BIN}" ]; then
        echo "ERROR: herdr was not found after installation." >&2
        exit 1
    fi
fi

# `herdr integration install claude` writes ~/.claude/hooks/herdr-agent-state.sh
# and adds hook entries to ~/.claude/settings.json — check for the hook script
# so re-runs don't redo that.
HERDR_HOOK="${HOME}/.claude/hooks/herdr-agent-state.sh"
if [ -f "${HERDR_HOOK}" ]; then
    echo "herdr Claude Code integration already installed — nothing to do."
else
    echo "Installing herdr's Claude Code integration..."
    "${HERDR_BIN}" integration install claude
fi
