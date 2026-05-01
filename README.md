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

# On a work machine, skip personal-only apps (obsidian, handy, ...)
./install.sh --work
```

### Flags

| Flag | Purpose |
|------|---------|
| `--dry-run` | Print every action without making changes |
| `--skip-brew` | Skip Homebrew install and `brew bundle` |
| `--work` | Skip personal-only Brewfile entries (sets `HOMEBREW_BUNDLE_WORK=1`) |
| `--help` | Show usage |

To mark additional packages as personal-only, move them inside the `unless work?` block in `Brewfile`.

## What the Installer Does

1. **Installs Homebrew** (if not present)
2. **Installs all packages** from `Brewfile` (CLI tools, apps, fonts) — `--work` skips personal-only entries
3. **Configures macOS** settings: faster keyboard, no auto-correct, Raycast hotkey
4. **Backs up existing configs** to `~/.config-backup-YYYYMMDD-HHMMSS/` (preserves path structure to avoid filename collisions)
5. **Creates symlinks** from your home directory to this repo
6. **Configures git globals** — `core.excludesfile`, and (if `delta` is installed) `core.pager`, `interactive.diffFilter`, `delta.navigate`, `delta.line-numbers`, `merge.conflictstyle = zdiff3`
7. **Sets zsh as default shell** (adds to `/etc/shells` if needed)
8. **Installs TPM and tmux plugins** (auto-installs, no manual step needed)
9. **Installs Neovim providers** (Python via uv, Ruby, Node, Mermaid CLI)
10. **Creates secrets template** at `~/.secrets.example`

Since configs are symlinked, any changes you make to `~/.zshrc` or `~/.config/nvim/` are automatically reflected in this repo.

### Safety

- `set -euo pipefail` + `trap ERR` — script aborts on any uncaught error and prints the line number.
- `--dry-run` is fully honoured: no file is created or written, no `sudo`, no `curl | bash`, no global git config writes.
- Anything `install.sh` is about to overwrite (in `~/.zshrc`, `~/.config/`, `~/.claude/`, `~/.agents/`) is backed up to `~/.config-backup-…/` first.

### Work mode (`--work`)

Use on machines that should not get personal-only apps (current Mac at a new job, shared machines, etc.). Implementation:

- `install.sh --work` exports `HOMEBREW_BUNDLE_WORK=1` for `brew bundle`.
- The `Brewfile` defines `def work?` and gates personal items with `unless work?`.
- `HOMEBREW_BUNDLE_WORK` is `HOMEBREW_`-prefixed because `brew bundle` scrubs other env vars.

Currently skipped under `--work`: `obsidian`, `handy`. Add more by moving them inside the `unless work?` block in `Brewfile`.

## What's Included

### Shell (zsh)
- **Powerlevel10k** - Fast, customizable prompt
- **Zinit** - Plugin manager with lazy loading
- **Plugins** - syntax highlighting, autosuggestions, fzf-tab
- **Aliases** - git, docker, kubernetes, tmux shortcuts
- **Zoxide** - Smarter `cd` that learns your habits
- **Set as default** - Automatically configured as login shell

### Terminal Multiplexer (tmux)
- **Yugen theme** - Dark, minimal aesthetic
- **TPM plugins** - resurrect, continuum, vim-navigator (auto-installed)
- **Prefix: Ctrl-a** - Easier than default Ctrl-b
- **Vi mode** - Vim keybindings in copy mode

### Editor (Neovim)
- **AstroNvim v5** - Feature-rich Neovim distribution
- **LSP** - Language servers via Mason
- **Treesitter** - Better syntax highlighting
- **Jupyter notebooks** - molten-nvim, jupytext, image.nvim (Kitty graphics)
- **Testing** - neotest with pytest adapter and DAP debugging
- **Custom plugins** - lazygit, trouble, obsidian, render-markdown

### Window Manager (Aerospace)
- **Tiling** - Automatic window arrangement
- **Workspaces** - Organized by purpose (work, communication, etc.)
- **Vim navigation** - Alt+hjkl to move focus

### Terminal (Ghostty)
- **Fast** - GPU-accelerated rendering
- **Dark theme** - Matches the overall aesthetic
- **Nerd fonts** - GeistMono Nerd Font Mono
- **Chord keybindings** - Cmd+S leader for tabs, splits, navigation
- **Kitty graphics** - Image rendering passthrough for nvim

### Productivity Apps
- **Raycast** - Spotlight replacement (Command+Space)
- **Handy** _(personal-only — skipped with `--work`)_ - Offline speech-to-text transcription
- **Obsidian** _(personal-only — skipped with `--work`)_ - Knowledge management

### Git
- **git-delta** - Pretty `git diff` and `git log` output, side-by-side merges via `zdiff3`. Wired up by `install.sh` only when the `delta` binary is present, so `--skip-brew` machines don't break.
- **Global gitignore** - Symlinked from `dotfiles/.gitignore_global` (see below).
- **`.gitconfig`** is **not** symlinked — `user.name` / `user.email` stay per-machine.

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

**Apps:**
aerospace, ghostty, raycast, claude-code, codex, cmux, ngrok, gcloud-cli, nerd fonts. Personal-only (skipped with `--work`): obsidian, handy.

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
│   ├── .zshrc              # Shell config (symlinked)
│   ├── .tmux.conf          # Tmux config (symlinked)
│   ├── .gitconfig          # Reference only — NOT symlinked
│   ├── .gitignore_global   # Global gitignore (symlinked)
│   └── aliases/            # Sourced by .zshrc
├── nvim/                   # Neovim config (AstroNvim v5)
│   └── lua/plugins/        # Plugin configs (molten, neotest, obsidian, etc.)
├── aerospace/              # Window manager config
├── ghostty/                # Terminal config
├── lazygit/                # Lazygit config
├── marimo/                 # Marimo notebook config (templated, copied not symlinked)
├── claude/                 # Claude Code: agents/, rules/, commands/, settings.json
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
