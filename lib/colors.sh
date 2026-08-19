#!/usr/bin/env bash
#
# Shared color setup + semantic output helpers, sourced by install.sh,
# update.sh, and every scripts/*.sh / updates/*.sh so terminal output looks
# and behaves the same everywhere instead of each script picking its own
# colors. Colors only apply when stdout is an interactive terminal that
# supports them, so redirecting output to a log file stays plain, readable
# text.
#
# shellcheck shell=bash

if [ -t 1 ] && [ -n "${COLORTERM:-}" ] && { [ "${COLORTERM}" = "truecolor" ] || [ "${COLORTERM}" = "24bit" ]; }; then
    # 24-bit RGB, picked as exact hex rather than the 16-color tput setaf
    # N names (BLUE, GREEN, ...). This repo's own home/.config/kitty/
    # theme.conf (Rose Pine Moon) remaps those names to hues that don't
    # match what they're called - its "green" (slot 2) is #2998c5, a blue,
    # and its "blue" (slot 4) is #90d8e4, a light cyan; its "bright"
    # variants (slots 8-15) are identical to the normal ones too, so BOLD
    # doesn't shift a hue the way it does in most themes. Any theme is
    # free to do this - tput setaf can only ask for slot N, never for a
    # specific hue - so the only way to guarantee headers are actually
    # blue, or that GREEN and BLUE are actually distinguishable, is to
    # bypass the palette and give the terminal exact RGB values directly.
    BOLD="$(tput bold)"
    RESET="$(tput sgr0)"
    BLUE=$'\033[38;2;35;91;153m'      # #235B99 - dark, clearly blue
    ORANGE=$'\033[38;2;230;126;34m'   # #E67E22 - sub-headers
    CYAN=$'\033[38;2;22;160;133m'     # #16A085 - teal
    GREEN=$'\033[38;2;46;204;113m'    # #2ECC71 - emerald green
    YELLOW=$'\033[38;2;243;156;18m'   # #F39C12 - amber
    MAGENTA=$'\033[38;2;175;96;217m'  # #AF60D9 - purple
    RED=$'\033[38;2;231;76;60m'       # #E74C3C - red
    GRAY=$'\033[38;2;158;168;179m'    # #9EA8B3 - neutral slate
elif [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    # Fallback for terminals that don't advertise COLORTERM=truecolor (e.g.
    # a plain SSH session) - the best that can be done there is trust
    # whatever hues the terminal's own theme assigned to each slot.
    BOLD="$(tput bold)"
    RESET="$(tput sgr0)"
    BLUE="$(tput setaf 4)"
    CYAN="$(tput setaf 6)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    MAGENTA="$(tput setaf 5)"
    RED="$(tput setaf 1)"
    GRAY="$(tput setaf 7)"
    # No true orange in the basic 16 - use 256-color slot 208 where
    # available, otherwise fall back to plain yellow.
    if [ "$(tput colors 2>/dev/null || echo 0)" -ge 256 ]; then
        ORANGE="$(tput setaf 208)"
    else
        ORANGE="${YELLOW}"
    fi
else
    BOLD="" RESET="" BLUE="" ORANGE="" CYAN="" GREEN="" YELLOW="" MAGENTA="" RED="" GRAY=""
fi

# Each color has one job, so scanning scrollback tells you what kind of
# line you're looking at before you even read it:
#   BLUE     top-level phase banners (Phase 1/3, 2/3, 3/3)
#   ORANGE   sub-headers within a phase (-- Section, ==> stage)
#   CYAN     a change is happening right now (installing, downloading, ...)
#   GREEN    success - already satisfied, or just finished (ok)
#   YELLOW   non-fatal, needs a glance (warn)
#   MAGENTA  the user has to go do something themselves (action, in
#            install.sh/update.sh)
#   RED      fatal (err)
#   GRAY     a value being reused as-is, not a state change (value)

# A step is actively changing something on the machine right now -
# "Installing X...", "Downloading Y...", "Registering Z...". Distinct from
# ok() so scrollback shows what changed vs what was already fine.
change() { echo "${CYAN}$1${RESET}"; }

# A step is already satisfied, or just finished successfully - "already
# installed", "already the latest", "nothing to do", "wrote X". Confirms a
# good state, whether or not anything actually changed this run.
ok() { echo "${GREEN}$1${RESET}"; }

# A previously-set value (git identity, SSH key comment, ...) is being
# reused as-is this run - distinct from ok() because nothing was verified
# or completed just now, it's just what's already on file.
value() { echo "${GRAY}$1${RESET}"; }

# Needs attention but isn't fatal - a self-heal in progress, an
# ignored/invalid input. Not the same as "go do this yourself" (see
# install.sh's action()) - this is FYI, not a to-do.
warn() { echo "${BOLD}${YELLOW}$1${RESET}" >&2; }

# Fatal - the caller should exit non-zero right after this.
err() { echo "${BOLD}${RED}ERROR: $1${RESET}" >&2; }
