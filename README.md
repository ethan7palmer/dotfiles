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

If `./install.sh` reports "Permission denied", the executable bit was lost in
transit — run `chmod +x install.sh scripts/*.sh` and try again. (Git on
Windows does not record the bit; to set it in the repo itself, run
`git update-index --chmod=+x install.sh scripts/*.sh` and commit.)

## Status

This repo is **partially built**. Right now `install.sh` installs the
prerequisites and Claude Code, and nothing else — enough to get `claude`
running on the target machine so the rest of the repo can be built there.

Implemented:

| Script                   | Does                                                  |
| ------------------------ | ----------------------------------------------------- |
| `scripts/00-prereqs.sh`  | apt: curl, wget, stow, gnupg, ca-certificates, software-properties-common |
| `scripts/60-claude-code.sh` | Claude Code via Anthropic's signed apt repository   |

Still to write:

- `scripts/10-apt-packages.sh` — Kitty, Google Chrome (official apt repo)
- `scripts/20-zsh.sh` — zsh + zinit, `chsh` to zsh
- `scripts/30-git-config.sh` — `~/.gitconfig.local` identity, SSH keygen
- `scripts/40-neovim.sh` — neovim via apt
- `scripts/50-docker.sh` — Docker via Docker's official apt repo, `docker` group
- `scripts/70-herdr.sh` — herdr + `herdr integration install claude`
- `scripts/80-gnome-settings.sh` — `dconf load / < gnome/dconf-settings.ini`
- `scripts/90-stow-symlinks.sh` — stow every package under `stow/`
- `stow/` — zsh, kitty, nvim, git, claude packages
- `gnome/dconf-settings.ini` — placeholder, captured on the target machine
- `install.sh` pre-flight prompts for git `user.name` / `user.email` /
  SSH key comment (exported as `DOTFILES_GIT_NAME`, `DOTFILES_GIT_EMAIL`,
  `DOTFILES_SSH_COMMENT`), plus the corresponding Phase 3 report lines

## Layout

```
dotfiles/
├── README.md
├── install.sh          # entrypoint: pre-flight → run scripts/ → report
└── scripts/            # numbered, idempotent, run in numeric order
```

`install.sh` runs every `scripts/*.sh` in numeric order, so adding a new step
means adding a numbered file — no edit to `install.sh` required.

## Conventions

- Every script uses `set -euo pipefail` and is safe to re-run. `install.sh` is
  both "first-time setup" and "update this machine".
- Prefer the apt package for anything that has one. Never snap. Fall back to a
  vendor install script only when no apt package exists.
- No secrets in the repo. Keys are generated on the target machine.
