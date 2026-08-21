#!/usr/bin/env bash
#
# GNOME/Ubuntu Dock appearance tweaks, applied on top of Ubuntu's actual
# defaults - not a config format that can wholesale overwrite unrelated
# settings. Deliberately individual `gsettings`/`xdg-settings` calls (not
# `dconf load`, which replaces everything under a path at once and is one
# bad/stale value away from a broken shell) so each change is small,
# reviewable in a diff, and independently reversible with `gsettings reset`.
#
set -euo pipefail
source "$(dirname "$0")/../lib/colors.sh"

# Only prints/changes anything if the current value differs - safe to re-run.
# Numeric values (e.g. mouse speed, a double) are compared numerically, since
# gsettings' float serialization (-0.40000000000000002) never exactly
# string-matches a plain literal like "-0.4".
set_gsetting() {
    local schema="$1" key="$2" value="$3"
    local current
    current=$(gsettings get "$schema" "$key")
    if [ "$current" = "$value" ]; then
        return
    fi
    if [[ "$value" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] && [[ "$current" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        if awk -v a="$current" -v b="$value" 'BEGIN { exit !(a == b) }'; then
            return
        fi
    fi
    change "Setting ${schema} ${key} -> ${value}"
    gsettings set "$schema" "$key" "$value"
}

# Chrome as default browser (the one thing already set by hand on this
# machine's first run - included so a fresh machine doesn't need that
# manual step).
if [ "$(xdg-settings get default-web-browser 2>/dev/null)" != "google-chrome.desktop" ]; then
    change "Setting default-web-browser -> google-chrome.desktop"
    xdg-settings set default-web-browser google-chrome.desktop
fi

# 24-hour clock.
set_gsetting org.gnome.desktop.interface clock-format "'24h'"

# Never blank the screen from inactivity (Settings -> Power -> Screen Blank
# -> Never). idle-delay is a uint32, and gsettings get/set both need that
# "uint32" type prefix on the literal for it to string-match on later runs -
# a bare "0" would set fine but never equal the "uint32 0" that get returns.
set_gsetting org.gnome.desktop.session idle-delay "uint32 0"

# Mouse: slightly slower than GNOME's default, no acceleration curve (flat =
# constant scaling derived from the speed value below, rather than
# speed-dependent acceleration).
set_gsetting org.gnome.desktop.peripherals.mouse accel-profile "'flat'"
set_gsetting org.gnome.desktop.peripherals.mouse speed "-0.5"

# Free up Ctrl+Alt+Up/Down (GNOME's default workspace-switching shortcut,
# unused here - not the muscle memory this machine is set up for) so it
# reaches apps instead - specifically home/.config/nvim's multicursor.nvim
# keymaps, which GNOME was silently swallowing these two keys before ever
# reaching Kitty. "@as []" is gsettings' own empty-array-of-strings
# representation for an unbound shortcut.
set_gsetting org.gnome.desktop.wm.keybindings switch-to-workspace-up "@as []"
set_gsetting org.gnome.desktop.wm.keybindings switch-to-workspace-down "@as []"

# Ubuntu Dock: bottom of the screen, shrunk to fit its icons (not stretched
# the full width) rather than centering it manually, auto-hidden rather than
# always reserving screen space.
set_gsetting org.gnome.shell.extensions.dash-to-dock dock-position "'BOTTOM'"
set_gsetting org.gnome.shell.extensions.dash-to-dock extend-height "false"
set_gsetting org.gnome.shell.extensions.dash-to-dock dock-fixed "false"

# Dock contents: only the pinned favorites below - no mounted drives, no
# trash can, and no icons for other apps just because they happen to be
# running.
set_gsetting org.gnome.shell.extensions.dash-to-dock show-mounts "false"
set_gsetting org.gnome.shell.extensions.dash-to-dock show-trash "false"
set_gsetting org.gnome.shell.extensions.dash-to-dock show-running "false"

# Dock icon size: smaller than Ubuntu's 48px default.
set_gsetting org.gnome.shell.extensions.dash-to-dock dash-max-icon-size "32"

# Pinned apps: just the two actually used day to day (no Files/Nautilus).
set_gsetting org.gnome.shell favorite-apps \
    "['google-chrome.desktop', 'kitty.desktop']"

# Desktop icons (the ding extension): no "Home" icon cluttering the desktop.
set_gsetting org.gnome.shell.extensions.ding show-home "false"

# Background: a custom image tracked in this repo (home/.local/share/backgrounds/),
# not a system file - stow must have already symlinked it into place by the
# time this runs (scripts/12-stow-symlinks.sh), which is why gnome-settings
# is numbered after stow.
#
# The actual desktop background (as opposed to the live preview in Settings
# -> Appearance, which reads the file directly) is drawn by Mutter, which
# keeps its own in-memory cache of loaded background images keyed by file
# *path* - editing wallpaper.jpg in place and re-pointing gsettings at the
# same path again doesn't reload it, because from Mutter's side nothing
# about the path changed, and there's no way to force a full cache flush
# short of restarting the session (not doable on Wayland without logging
# out). So instead of reusing wallpaper.jpg's path directly, copy it to a
# content-hashed filename and point gsettings at *that* - unchanged content
# always resolves to the same hash (a no-op re-run), and changed content
# always gets a path Mutter has never cached, guaranteeing a real reload.
# Stale previous-hash copies are cleaned up so this directory doesn't grow
# without bound.
SRC="${HOME}/.local/share/backgrounds/wallpaper.jpg"
HASH="$(sha256sum "$SRC" | cut -c1-16)"
CACHED="${HOME}/.local/share/backgrounds/.wallpaper-${HASH}.jpg"
if [ ! -e "$CACHED" ]; then
    find "${HOME}/.local/share/backgrounds" -maxdepth 1 -name '.wallpaper-*.jpg' -delete
    cp "$SRC" "$CACHED"
fi
set_gsetting org.gnome.desktop.background picture-uri "'file://${CACHED}'"
set_gsetting org.gnome.desktop.background picture-uri-dark "'file://${CACHED}'"

ok "GNOME settings applied."
