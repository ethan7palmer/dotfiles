# dotfiles

Personal provisioning repo for a fresh Ubuntu 26 machine. Clone it, run one
script, and it turns a stock install into a fully configured dev machine —
shell, terminal, editor, Docker, Git/SSH, Claude Code, voice dictation, and
GNOME's appearance.

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
those again, `--skip=STAGE,...` (e.g. `--skip=handy,docker`) or bare
`--skip` for a numbered checklist to leave stages out entirely, or `--help`
for all options.

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

**Browser** — Google Chrome, set as the default browser. Launches with
`--disable-features=Vulkan`: on an NVIDIA GPU under GNOME's default
Wayland session, Chrome's Wayland Ozone backend can't actually use
Vulkan, so every launch otherwise wastes several seconds attempting it
and falling back (`'--ozone-platform=wayland' is not compatible with
Vulkan` in the logs). Skipping the attempt removes that delay.

**Git & GitHub** — your name/email baked into git config, an SSH key
generated (or relabeled) for this machine, sane git defaults (aliases,
`pull.rebase`, etc).

**Docker** — Docker CE, with your user added to the `docker` group.

**Claude Code & herdr** — Anthropic's CLI, plus herdr (a session
sidebar/manager) wired up with native Claude Code session awareness.

**Desktop (GNOME)** — dock moved to the bottom, shrunk to fit its icons,
auto-hidden, showing only Chrome/Kitty (no drives, trash, unpinned running
apps, or Files), 32px dock icons, no Home icon cluttering the desktop, mouse
speed/acceleration tuned, 24-hour clock, and this repo's own wallpaper set
as the background.

**Voice dictation** — Handy, a local-only speech-to-text app (no audio ever
leaves the machine), plus `ydotool` (the text-injection backend it needs
under GNOME's default Wayland session) and a `Ctrl+Alt+Space` shortcut to
toggle it. Its default model (Parakeet Unified EN 0.6B, Handy's own
top-recommended, English-only) is downloaded and selected up front, so
there's no first-run setup to click through — Handy is left running after
the script finishes, ready to use immediately. Launches at login without
popping its window (it just sits in the tray); a quiet audio cue (20%
volume) marks the start/stop of recording in place of Handy's on-screen
overlay, which stays off (its default on Linux — that overlay is known to
steal focus and break pasting the transcript back into the app you were
dictating into).

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
| `15-handy.sh` | Handy (signed GitHub release) + default model + ydotool (apt) + its GNOME shortcut |

Every script uses `set -euo pipefail` and is safe to re-run — nothing here
duplicates PATH entries, re-clones plugin repos, or errors on an
already-installed package.

## Where things come from

Everything this repo installs, grouped by source and how much scrutiny it
warrants — useful if you need to get this approved for a work machine.

**Ubuntu's own apt repos** (baseline OS trust): curl, wget, stow, gnupg,
ca-certificates, software-properties-common, jq, ripgrep, fd-find, kitty,
zsh, starship, vim, neovim, ydotool, minisign.

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
- Handy — the latest `.deb` from `cjpais/handy`'s GitHub releases,
  cryptographically verified before install with `minisign` against
  Handy's signing key (pinned in `15-handy.sh` itself, not fetched
  alongside the release it verifies — see the comment there for why that
  distinction matters). Its default model downloads from a second source,
  `blob.handy.computer` (Handy's own model mirror), checked only against a
  SHA256 pinned in `15-handy.sh` from Handy's `catalog.json` at the time
  it was written — the same trust-on-first-use pattern as the signing key
  above, not a live signature, and a weaker guarantee than the `.deb`'s
  (a checksum proves the file matches what was pinned, not that the pin
  itself was ever independently trustworthy).

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
    ├── .local/share/
    │   ├── backgrounds/wallpaper.jpg   # desktop background
    │   └── applications/google-chrome.desktop   # adds --disable-features=Vulkan
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

**Handy's hotkey is a GNOME custom shortcut, not Handy's own in-app one.**
Handy's built-in global-shortcut handling (`rdev`) can't register
system-wide shortcuts under Wayland, which is GNOME's default session on
Ubuntu 26. Handy's own docs work around this by having the desktop
environment own the keybinding and call Handy's CLI instead
(`handy --toggle-transcription`) — `15-handy.sh` sets that up as a GNOME
custom keybinding via `gsettings`, the same individual-key pattern as the
rest of the desktop settings above.

**Handy's settings file location and shape are verified against its
source, not its README.** Handy's own docs state its Linux app-data
directory is `~/.config/com.pais.handy`; the real one (confirmed by
checking what Handy itself wrote there on first launch) is
`~/.local/share/com.pais.handy` — standard Tauri `app_data_dir()`
resolution, nothing Handy-specific. The settings file itself is also not
a flat object — every field lives nested one level down, under a
`"settings"` key (`store.set("settings", ...)` in Handy's own
`settings.rs`), which nothing in the README mentions either. `15-handy.sh`
writes to the real path and shape, pinned against source, not prose.

**Chrome's Vulkan flag lives in a `.desktop` override, not a flags file.**
Chromium supports a `~/.config/google-chrome-flags.conf` file on some
builds, but this Google-distributed `.deb`'s launcher
(`/usr/bin/google-chrome-stable`) doesn't read one — checked directly by
watching whether the flag actually showed up in the running process's
`/proc/<pid>/cmdline`; it never did. What does work, verified the same
way, is a user-level XDG override at
`~/.local/share/applications/google-chrome.desktop`, which — being in
`$XDG_DATA_HOME` — takes priority over `/usr/share/applications/` for the
same desktop-file-id without touching the package-owned original. It's a
trimmed copy of Chrome's own file (dropped: ~50 languages' worth of
`GenericName[xx]`/`Name[xx]` translations on the `Exec` lines this repo
needs to add the flag to; kept: everything that affects how the file
actually behaves as a launcher). Trimming means it won't inherit
translation or MIME-type updates from future Chrome packages — acceptable
for a single-user, English-language machine, but the tradeoff to know
about if that ever changes.
Because Handy loads this file into memory once and periodically flushes
its own copy back to disk, the script also stops any running Handy
instance before editing the file and restarts it after — editing it live
underneath a running instance loses the edit to Handy's next autosave.

## Conventions

- Prefer the apt package for anything that has one. Never snap. Fall back to
  an official vendor install script only when no apt package exists (Hack
  Nerd Font, Docker, herdr, Handy), verifying a cryptographic signature
  before install wherever the vendor publishes one (Handy).
- No secrets in the repo — SSH keys and git identity are generated/entered
  on the target machine, not shipped here.
