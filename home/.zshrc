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

# Starship (if installed) replaces the PROMPT set above with its own dynamic
# prompt on every command — keeping the plain one above means there's still
# a working colored prompt if starship isn't installed.
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
