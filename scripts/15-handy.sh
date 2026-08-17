#!/usr/bin/env bash
#
# Install Handy (github.com/cjpais/handy) — an open-source, MIT-licensed,
# local-only speech-to-text app — plus the pieces it actually needs to work
# under GNOME's default Wayland session on Ubuntu 26:
#
#   - ydotool, the text-injection backend. Handy's usual Wayland path
#     (`wtype`) doesn't work on Ubuntu 26.04 (see Handy's own README,
#     "Linux Notes"); ydotool is the documented fallback there.
#   - A GNOME custom keyboard shortcut. Handy's in-app global shortcut UI
#     is a no-op on Wayland (its `rdev` backend can't register system
#     shortcuts there) — Handy's docs say to bind a desktop-level shortcut
#     to a CLI flag instead, which is what this does.
#
# Also downloads Handy's own recommended default model and seeds its
# settings (quiet audio feedback, launch-at-login without popping its
# window, selected model, onboarding marked complete) before first launch,
# so the app is ready to use immediately with no interactive setup — see
# Handy's own catalog.json for where the model choice comes from.
# Microphone permissions are the one thing still necessarily interactive
# (the OS has to ask).
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Handy itself: latest .deb release, verified against Handy's minisign
# signing key before it's installed.
# ---------------------------------------------------------------------------

if dpkg -s handy >/dev/null 2>&1; then
    echo "Handy already installed — nothing to do."
else
    echo "Installing Handy..."

    if ! dpkg -s minisign >/dev/null 2>&1; then
        echo "Installing minisign (used to verify Handy's release signature)..."
        sudo apt update
        sudo apt install -y minisign
    fi

    # Pinned from Handy's own src-tauri/tauri.conf.json
    # (plugins.updater.pubkey), verified against the v0.9.5 release while
    # writing this script. Deliberately hardcoded rather than fetched at
    # install time — fetching the "trusted" key from the same GitHub repo
    # it's meant to verify would let a compromised repo defeat the check by
    # rotating both the key and the release at once.
    HANDY_PUBKEY_B64="dW50cnVzdGVkIGNvbW1lbnQ6IG1pbmlzaWduIHB1YmxpYyBrZXk6IEJBQjcyMDk1MjA2NjAxRjkKUldUNUFXWWdsU0MzdXRRZi8zYzhqV2FaNUVDbDd2Rk5VM1IvWWowVXdmRFNKQ1BrMXF5RFFsLy8K"

    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "${TMP_DIR}"' EXIT

    RELEASE_JSON="$(curl -fsSL https://api.github.com/repos/cjpais/Handy/releases/latest)"
    DEB_URL="$(jq -r '.assets[] | select(.name | test("amd64\\.deb$")) | .browser_download_url' <<<"${RELEASE_JSON}")"
    SIG_URL="$(jq -r '.assets[] | select(.name | test("amd64\\.deb\\.sig$")) | .browser_download_url' <<<"${RELEASE_JSON}")"
    DEB_NAME="$(basename "${DEB_URL}")"

    curl -fsSL "${DEB_URL}" -o "${TMP_DIR}/${DEB_NAME}"
    curl -fsSL "${SIG_URL}" -o "${TMP_DIR}/${DEB_NAME}.sig"

    base64 -d <<<"${HANDY_PUBKEY_B64}" >"${TMP_DIR}/handy.pub"
    # Handy's .sig release assets are themselves base64-encoded text
    # wrapping the actual minisign signature — see Handy's README,
    # "Verify Release Signatures".
    base64 -d "${TMP_DIR}/${DEB_NAME}.sig" >"${TMP_DIR}/${DEB_NAME}.minisig"

    echo "Verifying signature..."
    minisign -Vm "${TMP_DIR}/${DEB_NAME}" -p "${TMP_DIR}/handy.pub" -x "${TMP_DIR}/${DEB_NAME}.minisig"

    echo "Installing ${DEB_NAME}..."
    sudo apt install -y "${TMP_DIR}/${DEB_NAME}"
fi

# ---------------------------------------------------------------------------
# ydotool: install, group membership for /dev/uinput, and its systemd user
# service (Ubuntu's package ships both the unit and the udev rule already,
# so this is just enabling it and joining the group — no hand-written
# service file needed).
# ---------------------------------------------------------------------------

if ! dpkg -s ydotool >/dev/null 2>&1; then
    echo "Installing ydotool..."
    sudo apt update
    sudo apt install -y ydotool
fi

if id -nG "${USER}" | grep -qw input; then
    echo "${USER} already in the input group — nothing to do."
else
    echo "Adding ${USER} to the input group (needed for ydotoold to reach /dev/uinput)..."
    sudo usermod -aG input "${USER}"
fi

if systemctl --user is-enabled ydotool.service >/dev/null 2>&1; then
    echo "ydotool.service already enabled — nothing to do."
else
    echo "Enabling ydotool.service..."
    systemctl --user enable ydotool.service
fi

if ! systemctl --user is-active ydotool.service >/dev/null 2>&1; then
    # Fails silently if the input group membership above is new — it won't
    # take effect in this login session, only the next one.
    systemctl --user start ydotool.service 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# App preferences + default model, seeded before first launch so onboarding
# (model download, mic pick) is skipped entirely.
#
# Handy's app-data dir on Linux is ~/.local/share/com.pais.handy — despite
# Handy's own README stating ~/.config/com.pais.handy for this (confirmed
# wrong by checking what Handy itself actually wrote there on first launch).
# This is Tauri's standard app_data_dir() resolution (XDG_DATA_HOME), same
# as any other Tauri app; nothing Handy-specific about it.
#
# start_hidden is set true here (safe only because onboarding_completed is
# also forced true below — Handy has nothing to show on first launch that
# start_hidden could trap the user behind).
# ---------------------------------------------------------------------------

HANDY_DATA_DIR="${HOME}/.local/share/com.pais.handy"
HANDY_SETTINGS="${HANDY_DATA_DIR}/settings_store.json"
HANDY_MODELS_DIR="${HANDY_DATA_DIR}/models"

# Handy's default is 1.0 (100%) — quieter so the recording start/stop cue
# doesn't summon GNOME's volume OSD as jarringly as it did at full volume.
AUDIO_FEEDBACK_VOLUME="0.2"

# Handy's #1 recommended model in its own catalog (catalog.json,
# handy-computer/parakeet-unified-en-0.6b-gguf): fast, accurate English-only
# transcription. Pin filename/sha256 so a compromised mirror can't swap the
# file silently; the id string below is Handy's own registry key format
# ("{repo_id}/{filename}"), not something invented here — see
# managers/model.rs's ModelDescriptor::render_model_info.
MODEL_ID="handy-computer/parakeet-unified-en-0.6b-gguf/parakeet-unified-en-0.6b-Q8_0.gguf"
MODEL_FILENAME="parakeet-unified-en-0.6b-Q8_0.gguf"
MODEL_URL="https://blob.handy.computer/handy-computer/parakeet-unified-en-0.6b-gguf/7e948f21b7bdbac698d3318db9d350f1096f3b6c/${MODEL_FILENAME}"
MODEL_SHA256="4b50b6dd862bf6e346929aaf4f5eaacec003bfa3f56462d6c874b41ef2f38795"

mkdir -p "${HANDY_MODELS_DIR}"

MODEL_PATH="${HANDY_MODELS_DIR}/${MODEL_FILENAME}"
if [ -f "${MODEL_PATH}" ] && echo "${MODEL_SHA256}  ${MODEL_PATH}" | sha256sum -c - >/dev/null 2>&1; then
    echo "Default model already downloaded — nothing to do."
else
    echo "Downloading default model (${MODEL_FILENAME}, ~700MB)..."
    curl -fsSL "${MODEL_URL}" -o "${MODEL_PATH}"
    echo "${MODEL_SHA256}  ${MODEL_PATH}" | sha256sum -c -
fi

if [ ! -f "${HANDY_SETTINGS}" ]; then
    echo "Seeding ${HANDY_SETTINGS}..."
    # Nested under "settings" — that's the literal store key Handy's Rust
    # code writes to (src-tauri/src/settings.rs: store.set("settings", ...)),
    # not a flat top-level object. Confirmed against the key tauri-plugin-store
    # actually uses, not assumed from the README (which got the app-data-dir
    # path wrong — see the comment above).
    jq -n --arg model "${MODEL_ID}" --argjson volume "${AUDIO_FEEDBACK_VOLUME}" \
        '{settings: {audio_feedback: true, audio_feedback_volume: $volume, autostart_enabled: true, start_hidden: true, selected_model: $model, onboarding_completed: true}}' \
        >"${HANDY_SETTINGS}"
else
    current_audio="$(jq -r '.settings.audio_feedback // false' "${HANDY_SETTINGS}")"
    current_volume="$(jq -r '.settings.audio_feedback_volume // -1' "${HANDY_SETTINGS}")"
    current_autostart="$(jq -r '.settings.autostart_enabled // false' "${HANDY_SETTINGS}")"
    current_start_hidden="$(jq -r '.settings.start_hidden // false' "${HANDY_SETTINGS}")"
    current_model="$(jq -r '.settings.selected_model // ""' "${HANDY_SETTINGS}")"
    if [ "${current_audio}" = "true" ] && [ "${current_volume}" = "${AUDIO_FEEDBACK_VOLUME}" ] \
        && [ "${current_autostart}" = "true" ] && [ "${current_start_hidden}" = "true" ] && [ -n "${current_model}" ]; then
        echo "Handy preferences already set — nothing to do."
    else
        # Handy loads this file into memory on launch and periodically
        # writes its own in-memory copy back to disk. Editing it on disk
        # while Handy is running races that autosave — Handy's next flush
        # silently overwrites this edit with its stale in-memory state.
        # Stop it first (if it's up) so the change actually sticks.
        if pgrep -x handy >/dev/null 2>&1; then
            echo "Stopping the running Handy instance to edit its settings safely..."
            pkill -x handy || true
            for _ in $(seq 1 20); do
                pgrep -x handy >/dev/null 2>&1 || break
                sleep 0.5
            done
        fi

        echo "Updating ${HANDY_SETTINGS}..."
        jq --arg model "${MODEL_ID}" --argjson volume "${AUDIO_FEEDBACK_VOLUME}" '
            .settings.audio_feedback = true |
            .settings.audio_feedback_volume = $volume |
            .settings.autostart_enabled = true |
            .settings.start_hidden = true |
            (if (.settings.selected_model // "") == "" then
                .settings.selected_model = $model | .settings.onboarding_completed = true
             else . end)
        ' "${HANDY_SETTINGS}" >"${HANDY_SETTINGS}.tmp"
        mv "${HANDY_SETTINGS}.tmp" "${HANDY_SETTINGS}"
    fi
fi

# ---------------------------------------------------------------------------
# GNOME shortcut: Ctrl+Alt+Space toggles transcription. Free in Ubuntu's
# default keybindings (Super+O and Super+Space, the other two candidates
# considered, are already taken by rotation-lock and input-source-switch).
# ---------------------------------------------------------------------------

KEYBINDINGS_SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
KEYBINDING_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/handy-toggle-transcription/"
KEYBINDING_SCHEMA="${KEYBINDINGS_SCHEMA}.custom-keybinding:${KEYBINDING_PATH}"

current_list="$(gsettings get "${KEYBINDINGS_SCHEMA}" custom-keybindings)"
if [[ "${current_list}" != *"${KEYBINDING_PATH}"* ]]; then
    echo "Registering Handy custom keybinding..."
    if [ "${current_list}" = "@as []" ]; then
        new_list="['${KEYBINDING_PATH}']"
    else
        new_list="${current_list%]}, '${KEYBINDING_PATH}']"
    fi
    gsettings set "${KEYBINDINGS_SCHEMA}" custom-keybindings "${new_list}"
fi

gsettings set "${KEYBINDING_SCHEMA}" name "Toggle Handy Transcription"
gsettings set "${KEYBINDING_SCHEMA}" command "handy --toggle-transcription"
gsettings set "${KEYBINDING_SCHEMA}" binding "<Control><Alt>space"

# ---------------------------------------------------------------------------
# Leave Handy actually running. Without this, the shortcut above does
# nothing useful until the next login (autostart) or a manual launch — on a
# fresh install there'd be no tray icon at all until the user thinks to
# start it themselves. --start-hidden here only affects this one launch
# (Handy's own persisted start_hidden preference is left false — see the
# comment above settings seeding for why).
# ---------------------------------------------------------------------------

if pgrep -x handy >/dev/null 2>&1; then
    echo "Handy is running — nothing to do."
else
    echo "Starting Handy..."
    nohup /usr/bin/handy --start-hidden >/dev/null 2>&1 &
    disown
fi

echo "Handy setup complete."
