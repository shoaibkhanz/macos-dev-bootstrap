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
```

## What the Installer Does

1. **Installs Homebrew** (if not present)
2. **Installs all packages** from Brewfile (CLI tools, apps, fonts)
3. **Configures macOS** settings for faster keyboard, disabled auto-correct, Raycast hotkey
4. **Backs up existing configs** to `~/.config-backup-TIMESTAMP/`
5. **Creates symlinks** from your home directory to this repo
6. **Configures git** to use the global gitignore
7. **Sets zsh as default shell** (adds to /etc/shells if needed)
8. **Installs TPM and tmux plugins** (auto-installs, no manual step needed)
9. **Creates secrets template** at `~/.secrets.example`

Since configs are symlinked, any changes you make to `~/.zshrc` or `~/.config/nvim/` are automatically reflected in this repo.

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
- **AstroNvim** - Feature-rich Neovim distribution
- **LSP** - Language servers via Mason
- **Treesitter** - Better syntax highlighting
- **Custom plugins** - lazygit, trouble, obsidian integration

### Window Manager (Aerospace)
- **Tiling** - Automatic window arrangement
- **Workspaces** - Organized by purpose (work, communication, etc.)
- **Vim navigation** - Alt+hjkl to move focus

### Terminal (Ghostty)
- **Fast** - GPU-accelerated rendering
- **Dark theme** - Matches the overall aesthetic
- **Nerd fonts** - Icons everywhere

### Productivity Apps
- **Raycast** - Spotlight replacement (Command+Space)
- **Handy** - Offline speech-to-text transcription

### Global Gitignore
Automatically ignores across all repos:
- `.DS_Store`, `._*` (macOS junk)
- `.claude/` (AI assistant files)
- `.env`, `.secrets` (credentials)
- `__pycache__/`, `.venv/` (Python)
- `node_modules/` (Node.js)

### Homebrew Packages

**Core CLI:**
git, zsh, tmux, neovim, ripgrep, fd, fzf, zoxide, bat, eza, jq, yq

**Development:**
uv (Python), lazygit, gh, node, go, rust, lua-language-server

**Kubernetes & Cloud:**
kubectl, kubecolor, helm, k9s, kind, argocd, awscli, terraform

**Docker:**
docker, docker-compose, lazydocker

**Apps:**
aerospace, ghostty, raycast, handy, nerd fonts

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
3. **Configure Handy** - Set your preferred hotkey in the app
4. **Add your secrets:**
   ```bash
   cp ~/.secrets.example ~/.secrets
   nvim ~/.secrets  # Add your API keys
   ```

Note: Zsh is set as default shell and tmux plugins are installed automatically - no manual steps needed.

## Directory Structure

```
macos-dev-bootstrap/
├── install.sh              # Main setup script
├── Brewfile                # Homebrew packages
├── secrets.example         # Template for API keys
├── dotfiles/
│   ├── .zshrc              # Shell config
│   ├── .tmux.conf          # Tmux config
│   ├── .gitconfig          # Git config
│   └── .gitignore_global   # Global gitignore
├── nvim/                   # Neovim config
├── aerospace/              # Window manager config
├── ghostty/                # Terminal config
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

The script is idempotent - safe to run multiple times:

- Already-installed packages are skipped
- Already-symlinked files aren't backed up again
- Zsh default shell check is skipped if already set
- macOS settings are just reapplied

If something fails halfway, just run `./install.sh` again.

## License

MIT - Use however you like.
