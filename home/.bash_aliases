alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias ls='ls --color=auto'

# Show the herdr [keys] table straight from the config, so this can never
# drift out of sync with home/.config/herdr/config.toml. The config wraps
# the section in `# chs:start` / `# chs:end` markers that we grab here.
herdr-keys() {
    echo "herdr keybinds"
    awk '/# chs:start/{f=1;next} /# chs:end/{f=0} f' "$HOME/.config/herdr/config.toml"
}
