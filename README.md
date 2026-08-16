# dotfiles

Personal provisioning repo for a fresh Ubuntu 26 machine. Clone it, run one
script, and it turns a stock install into a fully configured dev machine —
shell, terminal, editor, Docker, Git/SSH, Claude Code, and GNOME's
appearance.

## Quick start

On a brand-new Ubuntu install, this is the entire manual part:

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/<USERNAME>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` shows you everything it's about to do and asks for confirmation
before touching anything. It's also safe to re-run any time (e.g. after
pulling a new script) — it reuses your existing git identity and SSH key
comment instead of re-asking. Pass `--update-identity` to be prompted for
those again, or `--help` for all options.

## What it sets up

**Shell & terminal** — zsh as the default shell (zinit, autosuggestions,
syntax highlighting, tab completion), Starship prompt, Kitty as the default
terminal (Hack Nerd Font Mono, Rosé Pine Moon theme, a slightly transparent
background, pink titlebar). A few muscle-memory fixes on top of zsh's
defaults: Ctrl+arrow jumps a word, Alt+Backspace stops at `/` instead of
deleting a whole path.

**Editor** — Neovim as the daily driver (lazy.nvim, which-key, a fuzzy
file/text finder, Neogit + gitsigns with a legible add/change/delete color
scheme, Rosé Pine Moon), plain `vim` with no configuration for quick edits.

**Browser** — Google Chrome, set as the default browser.

**Git & GitHub** — your name/email baked into git config, an SSH key
generated (or relabeled) for this machine, sane git defaults (aliases,
`pull.rebase`, etc).

**Docker** — Docker CE, with your user added to the `docker` group.

**Claude Code & herdr** — Anthropic's CLI, plus herdr (a session
sidebar/manager) wired up with native Claude Code session awareness.

**Desktop (GNOME)** — dock moved to the bottom, shrunk to fit its icons,
auto-hidden, showing only Chrome/Kitty/Files (no drives, trash, or unpinned
running apps), no Home icon cluttering the desktop, mouse speed/acceleration
tuned, 24-hour clock, and this repo's own wallpaper set as the background.

## Scripts

Everything under `scripts/` is one app or setting per file, numbered so they
run in a predictable order. Add a new step by adding a new numbered file —
`install.sh` picks it up automatically, no edits needed there.

| Script | What it does |
| --- | --- |
| `00-prereqs.sh` | curl, wget, stow, gnupg, jq, ripgrep, fd-find, and the apt-repo tooling the later scripts need |
| `01-kitty.sh` | Kitty terminal (apt) |
| `02-nerd-font.sh` | Hack Nerd Font Mono (no apt package exists — official GitHub release) |
| `03-chrome.sh` | Google Chrome (Google's official apt repo) |
| `04-zsh.sh` | zsh (apt) + zinit, sets it as the default shell |
| `05-starship.sh` | Starship prompt (apt) |
| `06-git-identity.sh` | Writes your git `user.name`/`user.email` |
| `07-ssh-key.sh` | Generates (or relabels) `~/.ssh/id_ed25519` |
| `08-vim.sh` | vim (apt), unconfigured |
| `09-neovim.sh` | Neovim (apt) + the full config described above |
| `10-docker.sh` | Docker CE (Docker's official apt repo) |
| `11-claude-code.sh` | Claude Code (Anthropic's signed apt repo) |
| `12-stow-symlinks.sh` | Symlinks everything in `home/` into `$HOME` |
| `13-gnome-settings.sh` | The desktop tweaks described above |
| `14-herdr.sh` | herdr (official installer) + Claude Code integration |

Every script uses `set -euo pipefail` and is safe to re-run — nothing here
duplicates PATH entries, re-clones plugin repos, or errors on an
already-installed package.

## Where things come from

Everything this repo installs, grouped by source and how much scrutiny it
warrants — useful if you need to get this approved for a work machine.

**Ubuntu's own apt repos** (baseline OS trust): curl, wget, stow, gnupg,
ca-certificates, software-properties-common, jq, ripgrep, fd-find, kitty,
zsh, starship, vim, neovim.

**Official vendor apt repos** (GPG-signed, each vendor's own documented
setup — standard practice, not a special exception):
- Google Chrome — `dl.google.com`
- Docker CE + cli + containerd.io + buildx + compose — `download.docker.com`
- Claude Code — `downloads.claude.ai`, Anthropic's own repo

**Direct downloads / vendor scripts** (no apt package exists):
- Hack Nerd Font Mono — a font tarball from `ryanoasis/nerd-fonts`'s GitHub
  releases. Static files, no code execution.
- Claude Code, fallback only if the apt install fails — Anthropic's own
  official `curl | bash` installer.
- herdr — `curl | sh` from `herdr.dev`. No `sudo`, installs only to
  `~/.local/bin`, downloads a prebuilt binary and verifies its SHA256
  against a manifest fetched from the same domain (protects against
  corruption/CDN issues, not against `herdr.dev` itself being compromised).

**Git-cloned source** (code that runs inside your shell/editor):
- zsh: [`zdharma-continuum/zinit`](https://github.com/zdharma-continuum/zinit)
  (plugin manager) → `zsh-users/zsh-autosuggestions`,
  `zsh-users/zsh-syntax-highlighting`. Not commit-pinned — tracks branch
  heads.
- Neovim: [`folke/lazy.nvim`](https://github.com/folke/lazy.nvim) (pinned to
  its `stable` branch) → `rose-pine/neovim`, `folke/which-key.nvim`,
  `stevearc/oil.nvim`, `folke/snacks.nvim`, `NeogitOrg/neogit`,
  `nvim-lua/plenary.nvim`, `sindrets/diffview.nvim`, `lewis6991/gitsigns.nvim`.
  All pinned to exact commits in `home/.config/nvim/lazy-lock.json`.

**Worth flagging on its own: herdr.** It's the newest and least-established
project of everything listed here, runs as a persistent background server,
and hooks into Claude Code session state via a `SessionStart` hook. The
installer itself is well-behaved (no `sudo`, checksum-verified, user-space
only), but its runtime behavior — what it does with session data, whether
it phones home — hasn't been independently audited as part of this repo.
Worth a look before running this on a company machine, separately from
everything else above.

## Repository layout

```
dotfiles/
├── install.sh     # entrypoint: pre-flight → run scripts/ → report
├── scripts/       # numbered, idempotent, run in numeric order (see above)
└── home/          # one Stow package, mirrors $HOME directly:
    ├── .config/
    │   ├── nvim/            # Neovim config (see "What it sets up" above)
    │   ├── kitty/            # kitty.conf + theme.conf
    │   ├── herdr/config.toml
    │   ├── starship.toml
    │   └── xdg-terminals.list   # makes Kitty the default terminal app
    ├── .local/share/backgrounds/wallpaper.jpg   # desktop background
    ├── .claude/               # CLAUDE.md + settings.json
    ├── .zshrc / .bashrc / .bash_aliases
    ├── .gitconfig / .gitignore_global
```

`home/` is a single [GNU Stow](https://www.gnu.org/software/stow/) package
rather than one per app — `scripts/12-stow-symlinks.sh` runs `stow -t "$HOME"
home` once, and Stow symlinks each file into place under `$HOME` (folding
into real directories like `~/.config` rather than replacing them outright).
To add a new stowed file, just add it under `home/` at the same relative
path it belongs at under `$HOME`.

Two separate `.gitignore` files, on purpose:

- `home/.gitignore_global` is symlinked to `~/.gitignore_global` and wired
  up as git's `core.excludesfile`, so it applies to *every* repo on the
  machine — generic, repo-agnostic junk only (`*.swp`, `.DS_Store`, etc).
- The repo-root `.gitignore` only applies to *this* repo — right now just
  herdr's own runtime files (logs, session state), which live inside the
  tracked `home/.config/herdr/` directory alongside the one file that
  actually is tracked, `config.toml`.

## A couple of deliberate design choices

**herdr runs after Stow, not before.** `herdr integration install claude`
writes a machine-specific absolute path into `~/.claude/settings.json`. If
it ran before Stow, that write would land in a plain file that Stow then
immediately overwrites with the tracked (path-free) copy — so herdr always
runs last, once `~/.claude/settings.json` is already the symlinked, shared
file. `home/.claude/settings.json` is deliberately committed *without* the
`hooks` key herdr adds; that key is expected to differ locally on every
machine, and that's fine.

**GNOME settings are individual `gsettings` calls, never a wholesale
`dconf load`.** Loading a full dconf dump replaces *everything* under that
path in one shot — one stale or machine-specific value (e.g. an extension
UUID that isn't installed here) can leave GNOME Shell unable to start
cleanly, with no obvious fix short of a full reinstall. Individual
`gsettings set` calls touch exactly one key each, show up as an ordinary
diff, and are each independently undoable with `gsettings reset`. The
script only overrides what actually differs from Ubuntu's own defaults —
everything else on the machine is left untouched.

## Conventions

- Prefer the apt package for anything that has one. Never snap. Fall back to
  an official vendor install script only when no apt package exists (Hack
  Nerd Font, Docker, herdr).
- No secrets in the repo — SSH keys and git identity are generated/entered
  on the target machine, not shipped here.
