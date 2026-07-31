# macOS Dev Bootstrap

One command to set up a fully configured macOS development environment.

## Why?

Setting up a new Mac is tedious - installing tools, configuring shells, setting up editors, tweaking system preferences. This repo automates all of it:

- **Reproducible** - Same setup every time, on any Mac
- **Version controlled** - Track changes to your configs over time
- **Portable** - Clone and run, no manual steps
- **Idempotent** - Safe to run multiple times (skips what's already done)

## Quick Start

```bash
# Clone the repo (anywhere you like)
git clone https://github.com/shoaibkhanz/macos-dev-bootstrap.git
cd macos-dev-bootstrap

# Preview what will happen
./install.sh --dry-run

# Run the installer
./install.sh

# On a work machine, skip personal-only apps (handy, ...)
./install.sh --work
```

### Flags

| Flag | Purpose |
|------|---------|
| `--dry-run` | Print every action without making changes |
| `--skip-brew` | Skip Homebrew install and `brew bundle` |
| `--work` | Skip personal-only Brewfile entries (sets `HOMEBREW_BUNDLE_WORK=1`) |
| `--herdr` | Only refresh herdr config + integrations, then exit (skips the full bootstrap) |
| `--claude` | Install Claude/agent skills, settings, rules & commands (default: **left untouched**) |
| `--help` | Show usage |

To mark additional packages as personal-only, move them inside the `unless work?` block in `Brewfile`.

## What the Installer Does

1. **Installs Homebrew** (if not present)
2. **Installs all packages** from `Brewfile` (CLI tools, apps, fonts) — `--work` skips personal-only entries. If `brew bundle` fails as a batch, the installer asks `brew bundle check` what's still missing and installs each entry on its own, so one broken cask costs exactly that cask instead of the whole Brewfile
3. **Installs Claude Code and omp** via their official installers (`curl … | bash` / `sh`), not Homebrew — skipped if already present
4. **Installs herdr agent integrations** (`pi`, `omp`, `claude`) — skipped if herdr isn't on `PATH`; a missing agent warns and continues
5. **Configures macOS** settings: faster keyboard, no auto-correct, Raycast hotkey
6. **Backs up existing configs and creates symlinks** — backup goes to `~/.config-backup-YYYYMMDD-HHMMSS/` (path structure preserved to avoid filename collisions); the symlinks and the Marimo config are written in the same step, so a failed backup stops the overwrite instead of clobbering configs that were never copied
7. Symlinks point from your home directory into this repo — Claude/agent config (`~/.claude/{skills,rules,commands,settings.json}`, `~/.agents/{skills,hooks,commands}`) is **skipped unless you pass `--claude`**, so pulling this repo onto another machine never clobbers its own skills/settings
8. **Installs herdr plugins** from GitHub (`herdr plugin install`) for every plugin `herdr/config.toml` binds a key to — skipped if herdr isn't on `PATH`, and a locally linked plugin is left as-is
9. **Configures git globals** — `core.excludesfile`, and (if `delta` is installed) `core.pager`, `interactive.diffFilter`, `delta.navigate`, `delta.line-numbers`, `merge.conflictstyle = zdiff3`
10. **Sets zsh as default shell** (adds to `/etc/shells` if needed)
11. **Installs TPM and tmux plugins** — TPM is always cloned; the plugin install is skipped and reported as a failed step if `tmux` isn't on `PATH` (e.g. after a failed `brew bundle`)
12. **Installs Neovim providers** (Python via uv, Ruby, Node, Mermaid CLI)
13. **Creates secrets template** at `~/.secrets.example`

Since configs are symlinked, any changes you make to `~/.zshrc` or `~/.config/nvim/` are automatically reflected in this repo.

### Safety

- **Step isolation** — each step runs in its own subshell with `set -eE`. A step stops at its first failing command, the failure is logged, and the installer moves on to the next step. One bad step (a failed cask, a missing binary) no longer aborts the whole bootstrap.
- **Failure summary** — the run ends with a list of every failed step and exits `1`; a clean run exits `0`. Re-run `./install.sh` after fixing the cause — it is idempotent.
- `--dry-run` is fully honoured: no file is created or written, no `sudo`, no `curl | bash`, no global git config writes.
- Anything `install.sh` is about to overwrite (in `~/.zshrc`, `~/.config/`, `~/.claude/`, `~/.agents/`) is backed up to `~/.config-backup-…/` first.

### Key repeat needs a reboot

`configure_macos` sets key repeat below what System Settings offers — `KeyRepeat 1`
(15ms between repeats, GUI floor is 2/30ms) and `InitialKeyRepeat 10` (150ms before
the first repeat, GUI floor is 15/225ms) — plus `ApplePressAndHoldEnabled false`,
which is the gate: with press-and-hold on, a held key opens the diacritic popover
instead of repeating and the two values look like they did nothing.

**None of it applies to the session that ran the installer.** HIToolbox reads these
once per app at launch, so every app already running — including the terminal you
bootstrapped from — keeps the old rate until you reboot (a logout usually does it).
To confirm which side of the line an app is on, its launch time must be *later*
than the last write to the global prefs:

```bash
ps -Ao lstart,comm | grep '[g]hostty'
stat -f %Sm ~/Library/Preferences/.GlobalPreferences.plist
```

### Work mode (`--work`)

Use on machines that should not get personal-only apps (current Mac at a new job, shared machines, etc.). Implementation:

- `install.sh --work` exports `HOMEBREW_BUNDLE_WORK=1` for `brew bundle`.
- The `Brewfile` defines `def work?` and gates personal items with `unless work?`.
- `HOMEBREW_BUNDLE_WORK` is `HOMEBREW_`-prefixed because `brew bundle` scrubs other env vars.
- The flag is also passed to the one-at-a-time retry path. `brew bundle check`
  re-evaluates the `Brewfile`, so without it `work?` returns false there and the
  retry reinstalls precisely what `--work` just skipped.
- A few `install.sh` steps check `$WORK_MODE` directly, for personal-only
  changes that aren't packages.

Currently skipped under `--work`:

| Skipped | Where |
|---------|-------|
| `handy` | `Brewfile` |
| `tailscale`, `mosh`, `moshi-hook`, the `rjyo/moshi` tap | `Brewfile` — see [Remote access](#remote-access-moshi-from-ios-over-tailscale) |
| `configure_noninteractive_path` (the `~/.zshenv` PATH block) | `install.sh` |

Add a package by wrapping it in `unless work?` in `Brewfile`; add a step by
returning early on `[ "$WORK_MODE" = true ]`.

### Third-party taps (`trusted: true`)

Homebrew 6 refuses to load a formula or cask from an untrusted third-party tap
(`Refusing to load formula sst/tap/opencode from untrusted tap sst/tap`). Every
non-core tap in the `Brewfile` therefore carries `trusted: true`, which
`brew bundle` applies to the trust store (`~/.homebrew/trust.json`) before it
fetches anything. Add the flag to any new tap you introduce, or its packages
will never install.

## What's Included

### Shell (zsh)
- **Starship** - Fast, cross-shell prompt (configured in `starship.toml`)
- **Zinit** - Plugin manager with lazy loading
- **Plugins** - syntax highlighting, autosuggestions, fzf-tab
- **Aliases** - git, docker, kubernetes, tmux shortcuts (inlined in `.zshrc`)
- **Zoxide** - Smarter `cd` that learns your habits
- **Set as default** - Automatically configured as login shell

### Terminal Multiplexer (tmux)
- **Yugen theme** - Dark, minimal aesthetic
- **TPM plugins** - resurrect, continuum, vim-navigator (auto-installed)
- **Prefix: Ctrl-s** - herdr owns Ctrl-a as its prefix, so tmux uses Ctrl-s to avoid a collision
- **Vi mode** - Vim keybindings in copy mode

### Editor (Neovim)
- **AstroNvim v5** - Feature-rich Neovim distribution
- **LSP** - Language servers via Mason
- **Treesitter** - Better syntax highlighting
- **Jupyter notebooks** - molten-nvim, jupytext, image.nvim (Kitty graphics)
- **Testing** - neotest with pytest adapter and DAP debugging
- **Custom plugins** - lazygit, trouble, render-markdown

### Terminal (Ghostty)
- **Fast** - GPU-accelerated rendering
- **Dark theme** - Matches the overall aesthetic
- **Nerd fonts** - GeistMono Nerd Font Mono
- **Chord keybindings** - Cmd+S leader for tabs, splits, navigation
- **Kitty graphics** - Image rendering passthrough for nvim

### Productivity Apps
- **Raycast** - Spotlight replacement (Command+Space)
- **Handy** _(personal-only — skipped with `--work`)_ - Offline speech-to-text transcription

### Git
- **git-delta** - Pretty `git diff` and `git log` output, side-by-side merges via `zdiff3`. Wired up by `install.sh` only when the `delta` binary is present, so `--skip-brew` machines don't break.
- **Global gitignore** - Symlinked from `dotfiles/.gitignore_global` (see below).
- **`.gitconfig`** is **not** symlinked — `user.name` / `user.email` stay per-machine.

### Herdr
- **Theme** - Vesper theme
- **Toast delivery** - System notifications
- **Safe prefix bindings** - Tab navigation and rename use the Herdr prefix to avoid intercepting normal typing
- **Managed symlinks** - `config.toml` and the workspace-manager plugin config (`plugins/workspace-manager/config.yml` → `~/.config/herdr/plugins/config/herdr-plugin-workspace-manager/config.yml`) are symlinked; logs, sockets, and session state stay local. Themes in `herdr/themes/` are a reference library (palettes are pasted into `config.toml`), not symlinked.
- **Plugins** - `install.sh` installs every plugin the keybindings in `herdr/config.toml` address (`HERDR_PLUGINS` in `install.sh`); a binding whose plugin is missing resolves to `plugin_not_found` and the key silently does nothing. Verify with `herdr plugin list`. They need **Node.js** on `PATH`. A plugin you have linked locally (`herdr plugin link`, for plugin development) is left untouched.

  | Plugin id | Source | Keys |
  |---|---|---|
  | `herdr-nav-plus` | [shoaibkhanz/herdr-nav-plus](https://github.com/shoaibkhanz/herdr-nav-plus) | direct `Ctrl+h/j/k/l` — vim split → pane → workspace (paired with `nvim/after/plugin/herdr_nav.lua`, a verbatim copy of the plugin's `editor/nvim.lua`) |
  | `active-agent.jump` | [shoaibkhanz/herdr-active-agent-jump](https://github.com/shoaibkhanz/herdr-active-agent-jump) | `prefix+j` / `prefix+k` |
  | `attention.jump` | [milkyskies/herdr-attention](https://github.com/milkyskies/herdr-attention) | `prefix+a` |
  | `herdr-plugin-workspace-manager` | [razajamil/herdr-plugin-workspace-manager](https://github.com/razajamil/herdr-plugin-workspace-manager) | per-worktree layouts (event-driven, no key) |
- **Fast refresh** - `./install.sh --herdr` re-links the herdr configs, re-installs the plugins above, and re-runs `herdr integration install` for `pi`/`omp`/`claude` without running the rest of the installer — run it after pulling latest herdr changes.

### Global Gitignore
Automatically ignores across all repos:
- `.DS_Store`, `._*` (macOS junk)
- `.env`, `.secrets` (credentials)
- `__pycache__/`, `.venv/` (Python)
- `node_modules/` (Node.js)
- **AI assistant files:**
  - `.claude/`, `CLAUDE.md`, `claude.md`
  - `agents.md`, `AGENTS.md`
  - `.cursorrules`, `.cursorignore`
  - `.github/copilot-instructions.md`
  - `.aider*`

### Homebrew Packages

**Core CLI:**
git, zsh, tmux, neovim, ripgrep, fd, fzf, zoxide, bat, eza, jq, yq

**Development:**
uv (Python), lazygit, git-delta, gh, glab, node, go, rust, lua-language-server, luarocks, luajit, tree-sitter, tectonic

**Kubernetes & Cloud:**
kubectl, kubecolor, kustomize, helm, k9s, kind, argocd, awscli, terraform (via `hashicorp/tap` — no longer in homebrew-core since the BSL relicense)

**Docker:**
docker, docker-compose, lazydocker

**Utilities:**
btop, superfile, yazi, ffmpeg, imagemagick, pandoc, chafa

**Remote access** _(personal-only — skipped with `--work`)_**:**
tailscale, mosh, moshi-hook (via `rjyo/moshi`) — see [Remote access](#remote-access-moshi-from-ios-over-tailscale)

**Apps:**
ghostty, raycast, codex, ngrok, gcloud-cli, nerd fonts. Personal-only (skipped with `--work`): handy.

**Installed via official installers (not Homebrew):**
- **Claude Code** — `curl -fsSL https://claude.ai/install.sh | bash`
- **omp** (Oh My Pi) — `curl -fsSL https://omp.sh/install | sh`

**Herdr agent integrations:** `install.sh` runs `herdr integration install` for `pi`, `omp`, and `claude` (skipped if `herdr` is not on `PATH`).

### macOS Optimizations

| Setting | Effect |
|---------|--------|
| `KeyRepeat = 1` | Fastest key repeat speed |
| `InitialKeyRepeat = 10` | Shortest delay before repeat |
| `ApplePressAndHoldEnabled = false` | Key repeat instead of accent menu |
| `AppleKeyboardUIMode = 3` | Tab through all UI controls |
| `NSAutomaticSpellingCorrectionEnabled = false` | No auto-correct |
| `NSAutomaticQuoteSubstitutionEnabled = false` | No smart quotes |
| `raycastGlobalHotkey = Command-49` | Raycast opens with Command+Space |

## Remote access (Moshi from iOS, over Tailscale)

Drive herdr and its agents from an iPhone with [Moshi](https://getmoshi.app). The
brew entries land via `Brewfile`, but the rest needs admin rights, a browser
login and a QR scan, so it stays manual and one-time-per-machine.

**Personal machines only.** `./install.sh --work` skips the whole thing — the
`rjyo/moshi` tap, all three packages, and the `~/.zshenv` PATH step. Joining a
corporate laptop to a personal WireGuard mesh and opening an SSH ingress to it
is a policy problem, not just clutter. Nothing below should be run on one.

**Threat model:** the tailnet is the only way in. `sshd` is key-only, so even on
an untrusted LAN there is no password to guess, and no port is forwarded from
the router.

### 1. Enable Remote Login

`sudo systemsetup -setremotelogin on` **fails** unless the calling terminal holds
Full Disk Access (`Turning Remote Login on or off requires Full Disk Access
privileges`). Going straight to launchd avoids the TCC prompt entirely. The
service label is `com.openssh.sshd` — `com.apple.ssh` is the alias `systemsetup`
uses, and enabling that one alone leaves the plist's `Disabled => 1` in force:

```bash
sudo launchctl enable system/com.openssh.sshd
sudo launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist
nc -z 127.0.0.1 22 && echo "sshd listening"
```

`launchctl print system/com.openssh.sshd` reporting `state = not running` is
correct — the job is socket-activated and only spawns on a connection.

### 2. Make sshd key-only

`/etc/ssh/sshd_config` already ends with `Include /etc/ssh/sshd_config.d/*`, and
sshd takes the **first** value it sees for a keyword, so the `010-` prefix wins
over the shipped `100-macos.conf` and anything added later:

```bash
sudo tee /etc/ssh/sshd_config.d/010-moshi-hardening.conf <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
EOF
sudo /usr/sbin/sshd -T | grep -E 'passwordauthentication|permitrootlogin'
```

No restart needed (socket-activated sshd re-reads config per connection).
Verify a password login is refused — the reply must name `publickey` only:

```bash
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no "$USER@127.0.0.1"
# ai@127.0.0.1: Permission denied (publickey).
```

### 3. Join the tailnet

`brew install tailscale` is the CLI daemon, not the GUI app: it runs at boot as a
system daemon rather than only while a user is logged in, which is what a
remotely-reached machine needs.

```bash
sudo brew services start tailscale
sudo tailscale up --ssh=false --operator="$USER"
tailscale status --json | jq -r '.Self.DNSName'
```

`--ssh=false` is **load-bearing**. Tailscale SSH is a *different* server that
seizes port 22 for all tailnet traffic and authenticates by Tailscale identity,
bypassing `sshd` and `authorized_keys` completely — Moshi's key would never be
checked, and the connection hangs ~60s before a misleading auth error. Symptom:
every port works over the tailnet address *except* 22.
`--operator` lets you run `tailscale` without `sudo`.

### 4. Pair Moshi

Install Tailscale on the phone and sign in to the same tailnet first, or the
connection has no route. Then pair against the MagicDNS name — **never** the LAN
IP, which would defeat the point:

```bash
moshi-hook host setup --host "$(tailscale status --json | jq -r '.Self.DNSName' | sed 's/\.$//')" \
                      --user "$USER" --port 22 --name "$(scutil --get LocalHostName) (tailnet)"
```

Scan the QR in Moshi → Easy Pair. It is a bearer token: anyone who scans it
before it expires gets SSH access. `moshi-hook host list` shows pairings and
`moshi-hook host revoke` removes one.

### Herdr on the phone

Moshi detects herdr by running `herdr session list --json` over a
**non-interactive** SSH shell, which is why `configure_noninteractive_path` puts
Homebrew on `~/.zshenv` — see that function's comment. Confirm with:

```bash
ssh <host> 'command -v herdr mosh-server tmux'
```

Two settings must be changed by hand, because `herdr/config.toml` here departs
from herdr's defaults:

- **Settings → Shortcuts → Herdr → prefix must be `Ctrl-A`.** Moshi defaults the
  panel to `Ctrl-B`; every shortcut it sends is otherwise ignored.
- **The panel's tab row will not switch tabs.** `next_tab`/`previous_tab` are
  rebound to direct `Ctrl-N`/`Ctrl-P` (no prefix), so the panel's `prefix`+`n`
  chord no longer matches. Use `Ctrl-N`/`Ctrl-P`, or `prefix`+`w` for workspaces.

Only sessions whose server is *running* appear in the picker; the always-present
`default` entry is filtered out while stopped. Start one with `herdr` on the host.

## Post-Install

1. **Restart terminal** to use zsh with new config
2. **Open nvim** - lazy.nvim will auto-install plugins on first launch
3. **Verify Jupyter** - Open any `.ipynb` in nvim, use `,mi` to init kernel, `,ml` to run a line
4. **Configure Handy** _(personal install only)_ - Set your preferred hotkey in the app
5. **Add your secrets:**
   ```bash
   cp ~/.secrets.example ~/.secrets
   nvim ~/.secrets  # Add your API keys
   ```

Note: Zsh is set as default shell, tmux plugins are installed, and Neovim providers (Python, Ruby) are configured automatically.

## Directory Structure

```
macos-dev-bootstrap/
├── install.sh              # Main setup script (set -euo pipefail, trap ERR)
├── Brewfile                # Homebrew packages (Ruby — supports `unless work?`)
├── secrets.example         # Template for API keys
├── dotfiles/
│   ├── .zshrc              # Shell config (symlinked) — aliases inlined here
│   ├── .tmux.conf          # Tmux config (symlinked)
│   ├── .gitconfig          # Reference only — NOT symlinked
│   └── .gitignore_global   # Global gitignore (symlinked)
├── nvim/                   # Neovim config (AstroNvim v5)
│   └── lua/plugins/        # Plugin configs (molten, neotest, etc.)
├── ghostty/                # Terminal config
├── lazygit/                # Lazygit config
├── marimo/                 # Marimo notebook config (templated, copied not symlinked)
├── claude/                 # Claude Code: agents/, rules/, commands/, settings.json
├── herdr/                  # Herdr config
├── archive/                # Retired configs — not installed, not symlinked (see archive/README.md)
└── starship.toml           # Prompt config
```

## Updating Your Configs

Configs are symlinked, so changes sync automatically:

```bash
# After making changes to any config
cd /path/to/macos-dev-bootstrap
git add -A
git commit -m "Update configs"
git push
```

## Re-running the Installer

The script is idempotent — safe to run multiple times:

- Already-installed packages are skipped
- Already-symlinked files aren't backed up again (only non-symlink files in the watched paths trigger a backup)
- `git config --global` keys are only written when their current value differs (cleaner dry-run output)
- Zsh default shell check is skipped if already set
- macOS settings are just reapplied
- `--work` and the default mode produce different `Brewfile` resolutions but use the same idempotent install

If something fails halfway, the `trap ERR` will print the failing line number; just fix the cause and run `./install.sh` again.

## License

MIT - Use however you like.
