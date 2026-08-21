# Shell functions, kept separate from home/.bash_aliases so that file
# stays a quick, skimmable list of plain `alias name=value` lines - actual
# logic lives here instead. Shared with bash: function syntax is
# identical in both shells, so this is the single source of truth for
# both rather than keeping two copies in sync by hand (same reasoning as
# home/.bash_aliases itself).

# herdr and home/.config/tmux/tmux.conf are kept key-for-key identical on
# purpose (see the note above [keys] in herdr's config.toml) - one shared
# listing instead of two. The [keys] table itself is read straight from
# herdr's config.toml (wrapped in `# chs:start`/`# chs:end` markers), so
# it can never drift out of sync with it; kill_all_workspaces lives
# outside that table as a [[keys.command]] block, so it's hand-appended
# here and needs updating manually if it ever changes in either config.
mux-keys() {
    echo "herdr/tmux keybinds"
    awk '/# chs:start/{f=1;next} /# chs:end/{f=0} f' "$HOME/.config/herdr/config.toml"
    echo 'kill_all_workspaces = "prefix+shift+k"'
}
