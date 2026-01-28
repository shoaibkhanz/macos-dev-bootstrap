# macOS Dev Bootstrap

Portable setup for bootstrapping a new macOS dev machine.

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

## What's Included

### Configurations
- **zsh** - Shell config with Powerlevel10k, zinit plugins, aliases
- **tmux** - Terminal multiplexer with Yugen theme, TPM plugins
- **neovim** - AstroNvim setup with custom plugins
- **aerospace** - Tiling window manager for macOS
- **ghostty** - Terminal emulator config
- **starship** - Cross-shell prompt
- **global gitignore** - Ignores `.claude/`, `.DS_Store`, etc. everywhere

### Homebrew Packages
Core tools: git, zsh, tmux, neovim, ripgrep, fd, fzf, zoxide, bat, eza

Development: uv, lazygit, gh, node, go, rust

Kubernetes: kubectl, kubecolor, helm, k9s, kind, argocd

Docker: docker, docker-compose, lazydocker

### macOS Optimizations
- Fastest key repeat speed
- Full keyboard navigation (Tab through all controls)
- Disabled press-and-hold (enables proper key repeat)
- Disabled auto-correct and smart quotes

## Post-Install

1. Restart terminal or run `source ~/.zshrc`
2. In tmux, press `Ctrl-a + I` to install plugins
3. Open nvim and let lazy.nvim install plugins
4. Create your secrets file:
   ```bash
   cp ~/.secrets.example ~/.secrets
   nvim ~/.secrets  # Add your API keys
   ```

## Directory Structure

```
macos-dev-bootstrap/
├── install.sh          # Main setup script
├── Brewfile            # Homebrew packages
├── secrets.example     # Template for API keys
├── dotfiles/
│   ├── .zshrc          # Zsh configuration
│   ├── .tmux.conf      # Tmux configuration
│   ├── .gitconfig      # Git configuration
│   └── .gitignore_global  # Global gitignore
├── nvim/               # Neovim/AstroNvim config
├── aerospace/          # Window manager config
├── ghostty/            # Terminal config
└── starship.toml       # Prompt config
```

## Updating

After running the installer, your configs are symlinked. Changes you make in `~/.zshrc`, `~/.config/nvim/`, etc. are reflected in this repo.

```bash
cd /path/to/macos-dev-bootstrap
git add -A
git commit -m "Update configs"
git push
```
