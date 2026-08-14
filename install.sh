#!/usr/bin/env bash
#
# Entrypoint for provisioning this machine.
#
#   Phase 1 — interactive pre-flight (summary + explicit confirmation)
#   Phase 2 — unattended execution of scripts/*.sh in numeric order
#   Phase 3 — final report of what still needs a human
#
set -euo pipefail

cd "$(dirname "$0")"

# ---------------------------------------------------------------------------
# Phase 1 — interactive pre-flight
# ---------------------------------------------------------------------------

cat <<'SUMMARY'

This will install the following on this machine:

  Prerequisites (apt)
    curl, wget, stow, gnupg, ca-certificates, software-properties-common
    — needed by the remaining scripts, and to add third-party apt repos.

  Claude Code (apt, via Anthropic's signed repository)
    Adds the Claude Code signing key to /etc/apt/keyrings, registers the
    stable channel in /etc/apt/sources.list.d, then installs `claude-code`.
    Falls back to the official install script only if apt cannot install it.

No config files are symlinked and no git identity is written by this run.

SUMMARY

reply=""
read -r -p "Continue? [y/N] " reply || true
case "$(printf '%s' "$reply" | tr '[:upper:]' '[:lower:]')" in
    y | yes) ;;
    *)
        echo "Aborted, no changes made."
        exit 0
        ;;
esac

# ---------------------------------------------------------------------------
# Phase 2 — unattended execution
# ---------------------------------------------------------------------------

# Recorded before anything runs, so the Phase 3 report can describe what
# actually changed rather than just what the end state looks like.
claude_was_present=false
if command -v claude >/dev/null 2>&1; then
    claude_was_present=true
fi

for script in scripts/*.sh; do
    echo
    echo "==> Running ${script}"
    bash "${script}"
done

# ---------------------------------------------------------------------------
# Phase 3 — final report
# ---------------------------------------------------------------------------

echo
echo "==> Done. What to do next:"
echo

if [ "${claude_was_present}" = false ]; then
    cat <<'NEXT'
  * Authenticate Claude Code.
    The first time you run `claude` it opens a browser to log in. This is
    expected — nothing here scripts or stores credentials. Claude Code needs
    a Pro, Max, Team, Enterprise, or Console account.

NEXT
fi

if ! command -v claude >/dev/null 2>&1; then
    cat <<'NEXT'
  * `claude` is not on your PATH in this shell.
    If it was just installed via the official install script it lives in
    ~/.local/bin — open a new shell, or add that directory to your PATH.

NEXT
fi

cat <<'NEXT'
  * The rest of this repo is not built yet.
    Only the prerequisites and Claude Code are implemented. See "Status" in
    README.md for the scripts and stow packages still to be written.

NEXT
