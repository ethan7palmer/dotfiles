# dotfiles

Personal provisioning repo for a fresh Ubuntu 26 machine.

## Day 0

On a brand-new Ubuntu install, this is the entire manual part:

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/<USERNAME>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Re-running `./install.sh` later (e.g. after pulling a new script) reuses your
existing git identity and SSH key comment silently instead of re-asking —
pass `--update-identity` to be prompted for them again, or `--help` for
usage.

## Status

This repo is **partially built**. Implemented so far: prereqs, Kitty + Hack
Nerd Font Mono + Chrome, zsh + zinit + Starship, git identity + SSH key,
vim, Neovim + lazy.nvim config, Docker, Claude Code, herdr, and symlinking
`home/` into `$HOME` via stow. Nothing here needs to be installed by hand —
`install.sh` installs everything listed below itself.

Every script is one app/package, run in numeric order, counting up from 0.

Implemented:

| Script                        | Installs                                              |
| ------------------------------ | ----------------------------------------------------- |
| `scripts/00-prereqs.sh`        | curl, wget, stow, gnupg, ca-certificates, software-properties-common, jq, ripgrep, fd-find (via apt; symlinks `fdfind` to `fd`) |
| `scripts/01-kitty.sh`          | Kitty terminal emulator (apt)                        |
| `scripts/02-nerd-font.sh`      | Hack Nerd Font Mono (official GitHub releases — no apt package exists) |
| `scripts/03-chrome.sh`         | Google Chrome (official apt repo)                    |
| `scripts/04-zsh.sh`            | zsh (apt), zinit, `chsh` to zsh                      |
| `scripts/05-starship.sh`       | Starship prompt (apt), wired into `.bashrc`/`.zshrc` |
| `scripts/06-git-identity.sh`   | `~/.gitconfig.local` user.name/user.email (from `install.sh` pre-flight) |
| `scripts/07-ssh-key.sh`        | SSH keygen / comment relabel                         |
| `scripts/08-vim.sh`            | vim (apt), no configuration                          |
| `scripts/09-neovim.sh`         | Neovim (apt); config: lazy.nvim, which-key, oil.nvim + snacks.nvim, neogit + gitsigns, rose-pine (moon) |
| `scripts/10-docker.sh`         | Docker CE (official apt repo), adds `${USER}` to the `docker` group |
| `scripts/11-claude-code.sh`    | Claude Code via Anthropic's signed apt repository    |
| `scripts/12-stow-symlinks.sh`  | Symlinks `home/` into `$HOME` via `stow`, backing up real files first |
| `scripts/14-herdr.sh`          | herdr (official installer) + `herdr integration install claude` — runs *after* stow on purpose (see below) |

`install.sh`'s pre-flight prompts for git `user.name` / `user.email` / SSH
key comment (re-run-aware: shows current values as defaults) are also done.

Still to write:

- `scripts/13-gnome-settings.sh` — `dconf load / < gnome/dconf-settings.ini`
- `gnome/dconf-settings.ini` — placeholder, captured on the target machine

## Layout

```
dotfiles/
├── README.md
├── install.sh          # entrypoint: pre-flight → run scripts/ → report
├── .gitignore          # repo-local: this repo's own quirks (see below)
├── scripts/            # numbered, idempotent, run in numeric order
└── home/               # one stow package, mirrors $HOME directly, e.g.
    ├── .config/
    │   ├── nvim/
    │   │   ├── init.lua
    │   │   ├── lazy-lock.json
    │   │   └── lua/
    │   │       ├── vim_config.lua
    │   │       ├── plugin.lua        # bootstraps lazy.nvim
    │   │       ├── keys.lua
    │   │       └── plugins/
    │   │           ├── colorscheme.lua   # rose-pine, moon variant
    │   │           ├── git.lua           # neogit + gitsigns
    │   │           ├── navigation.lua    # oil.nvim + snacks.nvim
    │   │           └── ui.lua            # which-key.nvim
    │   ├── kitty/
    │   │   ├── kitty.conf
    │   │   └── theme.conf
    │   ├── herdr/config.toml
    │   └── starship.toml
    ├── .claude/
    │   ├── CLAUDE.md
    │   └── settings.json
    ├── .zshrc
    ├── .bashrc
    ├── .bash_aliases
    ├── .gitconfig
    └── .gitignore_global
```

Two different `.gitignore`s, on purpose: `.gitignore_global` (above) is
symlinked to `~/.gitignore_global` and wired up as git's `core.excludesfile`
in `home/.gitconfig`, so it applies to *every* repo on the machine — only
generic, repo-agnostic junk belongs there (`*.swp`, `.DS_Store`, etc). The
repo-root `.gitignore` only applies to *this* repo, for patterns specific to
its own structure — e.g. herdr writes runtime state (logs, sockets, a
session file) directly into `home/.config/herdr/`, since Stow symlinked
that whole directory as a unit the first time it didn't yet exist.

`install.sh` runs every `scripts/*.sh` in numeric order, so adding a new step
means adding a numbered file — no edit to `install.sh` required.

`home/` is a single GNU Stow package rather than one package per app —
`scripts/12-stow-symlinks.sh` runs `stow -t "$HOME" home` once. Stow folds
into existing real directories (like `~/.config`, which Ubuntu creates by
default) and symlinks individual entries inside them, so e.g. `~/.config/nvim`
becomes a symlink straight to `home/.config/nvim` without turning the whole
of `~/.config` into a symlink. To add a new stowed app, add its files under
`home/` in the same relative path they belong at under `$HOME`.

**Why herdr (14) runs after stow (12):** `herdr integration install claude`
writes directly into `~/.claude/settings.json` — a machine-specific absolute
path (`~/.claude/hooks/herdr-agent-state.sh`) baked in for whoever's home
directory it runs against. Since `~/.claude/settings.json` only becomes a
symlink into this tracked repo *after* stow runs, running herdr after stow
means that write always lands in the already-symlinked (and thus portable
across re-runs) file, rather than in a plain local file that stow would
later clobber with the tracked copy. `home/.claude/settings.json` itself is
deliberately committed *without* a `hooks` key — herdr regenerates it
locally on every machine that runs this repo, so the version you see live
in `~/.claude/settings.json` will legitimately differ from git's tracked
copy after `herdr integration install claude` runs. That's expected drift,
not something to "fix" by committing it back.

## Conventions

- Every script uses `set -euo pipefail` and is safe to re-run. `install.sh` is
  both "first-time setup" and "update this machine".
- Prefer the apt package for anything that has one. Never snap. Fall back to a
  vendor install script only when no apt package exists.
- No secrets in the repo. Keys are generated on the target machine.
