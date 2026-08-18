# Handy's minisign public key, pinned from its own src-tauri/tauri.conf.json
# (plugins.updater.pubkey) - verified against the v0.9.5 release. Shared
# between scripts/15-handy.sh (initial install) and updates/handy.sh
# (version checks) so this security-critical constant can't drift between
# the two - deliberately hardcoded rather than fetched at install/update
# time, since fetching the "trusted" key from the same GitHub repo it's
# meant to verify would let a compromised repo defeat the check by
# rotating both the key and the release at once.
#
# shellcheck shell=bash

HANDY_PUBKEY_B64="dW50cnVzdGVkIGNvbW1lbnQ6IG1pbmlzaWduIHB1YmxpYyBrZXk6IEJBQjcyMDk1MjA2NjAxRjkKUldUNUFXWWdsU0MzdXRRZi8zYzhqV2FaNUVDbDd2Rk5VM1IvWWowVXdmRFNKQ1BrMXF5RFFsLy8K"
