# Dotfiles Setup

Portable dotfiles package for bootstrapping a new macOS machine.

## Quick Start

```bash
# Clone the repo
git clone https://github.com/shoaibkhanz/configs.git ~/code/configs

# Run the installer
cd ~/code/configs/full_setup
./install.sh

# Or preview changes first
./install.sh --dry-run
```

## What's Included

### Configurations
- **zsh** - Shell config with Powerlevel10k, zinit plugins, aliases
- **tmux** - Terminal multiplexer with Yugen theme, TPM plugins
- **neovim** - AstroNvim setup with custom plugins
- **aerospace** - Tiling window manager for macOS
- **ghostty** - Terminal emulator config
- **starship** - Cross-shell prompt

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
full_setup/
├── install.sh          # Main setup script
├── Brewfile            # Homebrew packages
├── secrets.example     # Template for API keys
├── dotfiles/
│   ├── .zshrc          # Zsh configuration
│   ├── .tmux.conf      # Tmux configuration
│   └── .gitconfig      # Git configuration
├── nvim/               # Neovim/AstroNvim config
├── aerospace/          # Window manager config
├── ghostty/            # Terminal config
└── starship.toml       # Prompt config
```

## Updating

To update your dotfiles after making changes:

```bash
# Configs are symlinked, so changes in ~ are reflected here
cd ~/code/configs/full_setup
git add -A
git commit -m "Update configs"
git push
```
