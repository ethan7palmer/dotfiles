# Task: Build a personal Ubuntu 26 dotfiles repository

Create a GitHub-style dotfiles repository that can fully provision a brand-new
Ubuntu 26 machine from a stock install to a fully-configured dev machine,
using GNU Stow for config symlinking and a set of idempotent shell scripts
for installation. This is a personal, single-user repo (one git identity, one
owner) — keep it minimally scoped to what's explicitly requested below rather
than adding extra "nice to have" tools or config that hasn't been asked for.
The user will extend it themselves as they identify gaps.

## Non-negotiable constraints

- Target OS: Ubuntu 26 (assume apt, systemd, GNOME desktop).
- The only manual steps before automation takes over must be: install git,
  clone the repo, run one script. Nothing else should require the user to
  type ad hoc commands before `install.sh` starts.
- Config files must live in the repo and be **symlinked** (not copied) into
  `$HOME` via GNU Stow, so editing a file in the repo (e.g.
  `stow/zsh/.zshrc`) is what updates `~/.zshrc` — the repo is the source of
  truth and the home directory copy is just a symlink pointing at it.
- Every install script must be idempotent — safe to run multiple times
  without duplicating PATH entries, re-cloning plugin repos, erroring on
  already-installed packages, etc. The same entrypoint should work as both
  "first-time setup" and "update this machine."
- Use `set -euo pipefail` in every script. Fail loudly, don't silently skip
  errors.
- No secrets/keys committed to the repo. SSH key generation happens on the
  target machine, not shipped in the repo.
- **Always prefer the apt package for any piece of software when one exists.
  Do not use snap, ever, for anything.** Only fall back to an official
  vendor install script (like Docker's or herdr's) when there is no apt
  package at all.
- Do not add packages, aliases, plugins, or config that weren't explicitly
  requested below "because they're commonly useful." This is a personal repo
  the user will audit and extend — a small correct surface beats a large
  speculative one.

## Repository structure to create

```
dotfiles/
├── README.md
├── install.sh
├── scripts/
│   ├── 00-prereqs.sh
│   ├── 10-apt-packages.sh
│   ├── 20-zsh.sh
│   ├── 30-git-config.sh
│   ├── 40-neovim.sh
│   ├── 50-docker.sh
│   ├── 60-claude-code.sh
│   ├── 70-herdr.sh
│   ├── 80-gnome-settings.sh
│   └── 90-stow-symlinks.sh
├── stow/
│   ├── zsh/.zshrc
│   ├── kitty/.config/kitty/kitty.conf
│   ├── nvim/.config/nvim/init.lua
│   ├── git/.gitconfig
│   ├── git/.gitignore_global
│   ├── claude/.claude/CLAUDE.md
│   └── claude/.claude/settings.json
└── gnome/
    └── dconf-settings.ini
```

## Bootstrap (README.md, Day 0 section)

This must be the ENTIRE manual part before automation takes over — 3-4
commands max, copy-pasteable on a totally fresh Ubuntu 26 install with
nothing configured:

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/<USERNAME>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## install.sh (entrypoint)

`install.sh` has two phases: an interactive pre-flight, then unattended
execution.

### Phase 1 — interactive pre-flight

Before running anything, `install.sh` must:

1. Prompt for the values that get baked into config, explaining what each is
   used for right in the prompt text. This step must be re-run-aware: before
   prompting, check whether each value is already set on this machine
   (`git config --file ~/.gitconfig.local user.name`/`user.email` for git
   identity, presence of `~/.ssh/id_ed25519.pub` and its trailing comment
   for the SSH key), and if so, show the current value as the default and
   ask whether to keep it or override it, rather than blindly asking for a
   fresh value every run:
   - **Git `user.name`** — explain this is the author name attached to every
     commit made on this machine (shows up in `git log`, GitHub commit
     history, blame, etc.). First run: prompt for a value. Subsequent runs:
     show the existing value, e.g. `Git user.name [Jane Doe]: `, and let an
     empty answer (just pressing Enter) keep the current value; any typed
     answer overrides it.
   - **Git `user.email`** — explain this is the author email attached to
     every commit the same way, and that it should match (or be added to)
     the user's GitHub account if they want commits linked to their profile.
     Same detect-and-default-to-current behavior as `user.name` above.
   - **SSH key comment** — explain this is just a label attached to the
     generated SSH key (shown next to the key on GitHub's SSH keys page to
     help identify which machine/key it is), and suggest something like
     `<email>` or `<name>@<hostname>` as a sensible default on first run.
     On subsequent runs, if a key already exists at `~/.ssh/id_ed25519`,
     show its current comment as the default and ask whether to keep it —
     note clearly in the prompt that changing this on a re-run does **not**
     regenerate the key (that would invalidate anything already trusting the
     old public key); it only relabels it, and only if the user explicitly
     opts to change it. If no key exists yet, behave as a normal first-run
     prompt.
2. Print a clear plain-text summary of everything that is about to happen —
   every package/tool this run will install and every piece of config it
   will symlink into place (prereqs, Chrome, Kitty, zsh + plugins, Neovim,
   git config with the values just entered, Docker, Claude Code, herdr,
   GNOME dconf load, and the Stow symlinking step) — then ask:
   `Continue? [y/N]` and **default to No** if the user just presses Enter or
   gives no clear "yes." Only proceed to Phase 2 on an explicit affirmative
   answer (`y`/`yes`, case-insensitive). Otherwise exit 0 with a friendly
   "aborted, no changes made" message.
3. Export the collected values as environment variables (e.g.
   `DOTFILES_GIT_NAME`, `DOTFILES_GIT_EMAIL`, `DOTFILES_SSH_COMMENT`) so the
   numbered scripts can read them — don't write them to disk until the
   relevant script actually applies them.

### Phase 2 — unattended execution

- `cd` to its own directory (`cd "$(dirname "$0")"`) so it works regardless
  of invocation location.
- Loop over `scripts/*.sh` in numeric order and run each with `bash`,
  printing a `==> Running X` banner before each, with the exported env vars
  from Phase 1 available to them.
- Must not require further confirmation prompts mid-run — from here on it
  runs unattended aside from things that inherently need interactive input,
  like apt's own sudo password prompt.

### Phase 3 — final report

After every script has run, print a clear "what to do next, and why" list.
This must be assembled dynamically based on what actually happened (e.g.
skip the SSH-key line if a key already existed), and should cover at least:

- **Docker group membership** — log out and back in (or reboot) for the
  new `docker` group membership to take effect; explain that until then
  `docker` commands will fail with a permissions error.
- **Claude Code authentication** — the first time `claude` is run it will
  prompt to log in / authenticate; note this so it isn't a surprise.
- **SSH key → GitHub** — print the public key contents (`cat ~/.ssh/id_ed25519.pub`)
  and a direct explanation: add it at github.com under Settings → SSH and
  GPG keys, so the user can push/pull over SSH and (if applicable) sign in
  to `gh` or clone private repos.
- **GitHub authentication for any CLI tooling actually installed** — only
  mention this if something in the scripts actually needs it (don't invent
  a `gh` CLI step if `gh` was never installed).
- **Shell change** — if the default shell was changed to zsh, note that a
  fresh terminal/login session is needed for it to take effect.
- Any other first-run prompts introduced by scripts added later.

## Script-by-script requirements

### scripts/00-prereqs.sh
- `sudo apt update`.
- Install only what's strictly required for the rest of the scripts to run:
  `curl`, `wget`, `stow`, `gnupg`, `ca-certificates`, `software-properties-common`
  (the last three needed for adding Chrome's and Docker's official apt repos).
- Check with `command -v` / `dpkg -s` first to keep it idempotent and avoid
  noisy re-installs.

### scripts/10-apt-packages.sh
- Install Kitty terminal emulator via the apt package (`kitty`), not snap
  and not the upstream install script.
- Install Google Chrome: add Google's official apt repo + signing key (not
  a PPA, not snap), then `apt install google-chrome-stable`.
- Nothing else — no speculative "nice to have" CLI tools.

### scripts/20-zsh.sh
- Install `zsh` via apt.
- Change the user's default shell to zsh with `chsh -s $(which zsh)`, but
  check current `$SHELL` first so it's idempotent and doesn't prompt for a
  password unnecessarily if already set.
- Install **zinit** as the plugin manager (lightweight, avoids Oh-My-Zsh's
  overhead) by cloning it to `~/.local/share/zinit/zinit.git` if not already
  present. This script only needs to ensure zinit itself is present — the
  actual plugin list lives in the stowed `.zshrc` (zinit installs/loads
  plugins declared there on first shell launch).
- Do not install anything beyond zsh + zinit in this script (no prompt
  frameworks, no extra plugins) unless it's required to satisfy the
  ghost-text autocompletion request below.

### scripts/30-git-config.sh
- Write `user.name` and `user.email` using the values resolved in
  `install.sh`'s pre-flight (`$DOTFILES_GIT_NAME`, `$DOTFILES_GIT_EMAIL`) —
  these are already either the existing values (kept) or the user's
  override, so this script just applies them unconditionally via a
  **separate, untracked** `~/.gitconfig.local` file
  (`git config --file ~/.gitconfig.local user.name "$DOTFILES_GIT_NAME"`,
  same for email). This keeps personal identity out of the tracked
  `stow/git/.gitconfig`, which instead `[include]`s `~/.gitconfig.local`.
- Everything else — the actual conventions (`init.defaultBranch main`,
  `pull.rebase true`, `push.autoSetupRemote true`, `core.editor nvim`,
  `color.ui auto`, `merge.conflictstyle diff3`, aliases `co`/`br`/`st`/`lg`,
  `core.excludesfile` pointing at `~/.gitignore_global`) lives statically in
  the tracked `stow/git/.gitconfig`, applied via Stow in step 90, not via
  scripted `git config` calls.
- If no SSH key exists at `~/.ssh/id_ed25519`, generate one non-interactively
  with
  `ssh-keygen -t ed25519 -C "$DOTFILES_SSH_COMMENT" -f ~/.ssh/id_ed25519 -N ""`.
  If a key already exists and the pre-flight recorded a comment override,
  relabel the existing key in place (`ssh-keygen -c`) rather than
  regenerating it — never silently regenerate an existing key. Do not print
  or upload the key here — that's handled in install.sh's final report
  (Phase 3).

### scripts/40-neovim.sh
- Install Neovim via the apt package (`neovim`), per the "always prefer
  apt" rule — do not use an AppImage or PPA even if the apt version is a
  bit behind upstream.
- This script just ensures the package is installed; the actual config
  content lives in `stow/nvim/.config/nvim/init.lua` (see below) and is
  applied via Stow in step 90.

### scripts/50-docker.sh
- Use Docker's official apt repo + GPG key setup exactly as documented by
  Docker (this is the one approved exception to "prefer apt" as a plain
  Ubuntu package, since Docker's own repo is the vendor-correct source —
  still not snap).
- Install `docker-ce docker-ce-cli containerd.io docker-buildx-plugin
  docker-compose-plugin`.
- Add the current user to the `docker` group if not already a member
  (`usermod -aG docker $USER`). Do not print the logout/login reminder here
  — that's handled centrally in install.sh's Phase 3 report.

### scripts/60-claude-code.sh
- Install Claude Code via Anthropic's documented install method (check
  current official instructions rather than assuming, since install methods
  change) — prefer apt/native package if one now exists, otherwise their
  official install script.
- Do not hardcode an API key or attempt to script authentication.

### scripts/70-herdr.sh
- Install herdr via its official installer:
  ```bash
  curl -fsSL https://herdr.dev/install.sh | sh
  ```
  Guard with a `command -v herdr` check first so re-runs don't reinstall.
- Run `herdr integration install claude` after Claude Code is installed, so
  herdr's sidebar gets native state-awareness for Claude Code sessions.
  Guard this so it's safe to re-run too.

### scripts/80-gnome-settings.sh
- Load `gnome/dconf-settings.ini` into dconf: `dconf load / < gnome/dconf-settings.ini`
  if that file exists and is non-empty.
- Ship the repo with an **empty placeholder** `gnome/dconf-settings.ini`
  (just a comment header) rather than baking in guessed GNOME preferences
  (dark mode, power settings, trackpad behavior, etc.) — those are
  unaudited assumptions about what the user wants. Document in the README
  how the user captures their own preferences later:
  `dconf dump / > gnome/dconf-settings.ini` run after they've made the GUI
  changes they want persisted.

### scripts/90-stow-symlinks.sh
- `cd` into the `stow/` directory.
- For each subdirectory (`zsh`, `kitty`, `nvim`, `git`, `claude`), run
  `stow -v -t "$HOME" <package>`.
- Do NOT use `stow --adopt` (it would overwrite repo files with existing
  home files, which is surprising). Instead, if a real file already exists
  at a target path (not a symlink) — e.g. Ubuntu's default `~/.bashrc` or a
  pre-existing `~/.gitconfig` — back it up to `<file>.pre-stow-backup` first,
  then stow normally, so first-run on a fresh Ubuntu install doesn't fail
  with "existing target is not a symlink."
- Loop over all directories under `stow/` automatically rather than
  hardcoding the package list, so adding a new stowed app later requires no
  script edit.

## Stow package contents to draft

### stow/zsh/.zshrc
Keep this minimal and directly tied to what was asked for — a shell with
ghost-text autocompletion — nothing extra:
1. zinit bootstrap/load (matching what `20-zsh.sh` installed to
   `~/.local/share/zinit/zinit.git`).
2. `zinit light zsh-users/zsh-autosuggestions` — this is the ghost-text
   completion that was explicitly requested.
3. `zinit light zsh-users/zsh-syntax-highlighting` — directly supports
   reading/using the autosuggestions comfortably.
4. Basic, non-speculative essentials only: `EDITOR=nvim`, reasonable
   history size/dedup options. Do not add aliases, prompt frameworks, or
   fzf/tool integrations that weren't requested — the user will add these
   themselves as they identify what they want.

### stow/kitty/.config/kitty/kitty.conf
A minimal, real starter config: a readable monospace font, a sane default
font size, and nothing else invented — no unaudited theme/keybinding
choices. Comment showing where the user can add more as they customize it.

### stow/git/.gitconfig
The static, tracked conventions described in `30-git-config.sh` above
(`init.defaultBranch`, `pull.rebase`, `push.autoSetupRemote`, `core.editor`,
`color.ui`, `merge.conflictstyle`, the four aliases, `core.excludesfile`),
plus an `[include] path = ~/.gitconfig.local` pointing at the untracked
per-machine identity file.

### stow/nvim/.config/nvim/init.lua
Write a real, minimal, working config now — no `TODO` placeholders, since
this is a single-user repo and the user wants it usable immediately. Keep
it to core built-in settings and keymaps only (no plugin manager, no
plugins — those weren't requested and would be unaudited assumptions):
line numbers (`number`, `relativenumber`), sane indentation
(`expandtab`, `shiftwidth=2`, `tabstop=2` — or the user's preferred width,
default to 2 if unspecified), `mouse=a`, system clipboard integration
(`clipboard=unnamedplus`), a leader key (`<Space>`), and a couple of
genuinely load-bearing keymaps (e.g. clearing search highlight, easier
window navigation). Nothing beyond core Neovim options/keymaps — no
external dependencies.

### stow/claude/.claude/CLAUDE.md and settings.json
Minimal starter files with placeholder structure and comments, since actual
content is personal preference the user will fill in — don't invent
opinionated agent instructions on the user's behalf.

## Final deliverable

A working repository matching the structure above, with:
- All scripts executable (`chmod +x`) and passing a `bash -n` syntax check.
- A README with the Day-0 bootstrap block clearly at the top, followed by
  a description of the repo layout, how to add a new stowed app, and how to
  regenerate the GNOME dconf snapshot.
- No hardcoded personal secrets, emails, or API keys anywhere — the git
  identity and SSH key comment come from the interactive pre-flight in
  `install.sh`, not from anything baked into the repo.

Ask the user only if something is genuinely ambiguous and consequential
(e.g. which Neovim indentation width to default to, if truly unspecified).
Otherwise use the sensible defaults specified above and proceed.
