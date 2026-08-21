# ~/.local/bin holds user-installed binaries (herdr, and some tools' own
# install scripts default here) that aren't on PATH by default.
export PATH="$HOME/.local/bin:$PATH"

export EDITOR=nvim
export VISUAL=nvim

# Bash-like interactive behavior, for muscle memory coming from bash:
# - zsh defaults to vi keybindings when EDITOR/VISUAL contains "vi" (which
#   "nvim" does) — force emacs-style (Ctrl-A/E/W/K/U, arrow-key history)
#   to match bash's actual default instead.
# - SH_WORD_SPLIT: unquoted $var word-splits on whitespace like bash/sh,
#   instead of zsh's default of treating it as a single word.
# - NOMATCH off: an unmatched glob is left as a literal pattern like bash's
#   default, instead of zsh's default of erroring "no matches found".
bindkey -e
setopt SH_WORD_SPLIT
unsetopt NOMATCH

# Ctrl-Left/Right (jump a word, like bash/readline) aren't bound by zsh's
# emacs keymap out of the box - Kitty sends the standard xterm sequence
# (confirmed: `bindkey` showed plain Left/Right bound but not these), so
# with no binding zsh just inserts the unrecognized tail as literal text
# (the ";5D" this was added to fix).
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# Alt+Backspace (backward-kill-word) treats $WORDCHARS as part of a "word"
# rather than a boundary, and zsh's default $WORDCHARS includes "/" - so it
# was deleting a whole path like /path/to/file in one go instead of stopping
# at each "/", like bash/readline do. Dropping "/" from the default set (the
# rest unchanged) makes it stop at path separators: /path/to/file -> /path/to/.
WORDCHARS=${WORDCHARS//\//}

# A zsh-native prompt (bash's PS1 escapes like \u/\h/\[...\] aren't
# meaningful here, so leaving this unset means anything that ever sets PS1
# — including accidentally sourcing ~/.bashrc from inside zsh — sticks until
# a new shell starts). Same look as bash's colored prompt: user@host:path$.
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%# '

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_SPACE

# Shared with bash: `alias name=value` syntax is identical in both shells,
# so home/.bash_aliases is the single source of truth for both rather than
# keeping two copies in sync by hand.
[ -f "$HOME/.bash_aliases" ] && source "$HOME/.bash_aliases"

# zinit bootstrap — matches the install path scripts/03-zsh.sh clones to.
# https://github.com/zdharma-continuum/zinit
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname "$ZINIT_HOME")"
[ ! -d "$ZINIT_HOME/.git" ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting

# Tab completion ignores dotfiles/dot-directories by default (matching
# glob behavior) unless what you've typed so far already starts with a
# literal "." - e.g. `cd home/<Tab>` finds nothing in a directory that
# holds only dotfiles, like this repo's own home/. GLOB_DOTS makes
# completion (and globs generally) consider dotfiles unless explicitly
# excluded, same as always passing `-A`/`ls -a`.
setopt GLOB_DOTS

# zsh's completion system (the thing that makes `cd <Tab>` list directories,
# and gives command-aware completion generally) isn't active until this
# runs — without it, Tab falls back to much more limited behavior.
autoload -Uz compinit
compinit

# Starship (if installed) replaces the PROMPT set above with its own dynamic
# prompt on every command — keeping the plain one above means there's still
# a working colored prompt if starship isn't installed.
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
