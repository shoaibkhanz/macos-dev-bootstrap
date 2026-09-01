# Dotfiles Brewfile
# Install with: brew bundle --file=Brewfile
#
# Work mode: HOMEBREW_BUNDLE_WORK=1 brew bundle --file=Brewfile
# (set automatically by `./install.sh --work`)
# Personal-only entries are wrapped in `unless work?` and skipped on work machines.
#
# Note: brew bundle scrubs the environment but preserves HOMEBREW_* vars,
# which is why this flag must be HOMEBREW_-prefixed.
#
# Mark an item as personal by wrapping it in `unless work?`.

def work?
  ENV["HOMEBREW_BUNDLE_WORK"] == "1"
end

# Taps. `trusted: true` is required since Homebrew 6: it refuses to load
# formulae/casks from untrusted third-party taps (UntrustedTapError), and
# `brew bundle` grants Brewfile-declared trust before its up-front fetch —
# without it the fetch fails and the bundle installs *nothing at all*.
tap "oven-sh/bun", trusted: true       # bun
tap "sst/tap", trusted: true           # opencode
tap "hashicorp/tap", trusted: true     # terraform (no longer in homebrew-core since BSL relicense)

# =============================================================================
# Core CLI Tools
# =============================================================================
brew "git"
brew "zsh"
brew "tmux"
brew "neovim"
brew "ripgrep"
brew "fd"
brew "fzf"
brew "zoxide"
brew "starship"
brew "bat"
brew "eza"
brew "jq"
brew "yq"
brew "wget"
brew "xh"              # Modern HTTP client
brew "coreutils"
brew "gnu-sed"

# =============================================================================
# Development Tools
# =============================================================================
brew "uv"              # Fast Python package manager
brew "pipx"            # Install/run Python CLI tools in isolation
brew "lazygit"         # Git TUI
brew "git-delta"       # Pretty git diffs (used as core.pager + interactive.diffFilter)
brew "gh"              # GitHub CLI
brew "glab"            # GitLab CLI
brew "node"
brew "oven-sh/bun/bun" # Fast JS runtime & package manager
brew "go"
brew "rust"
brew "bob"             # Neovim version manager
brew "lua-language-server"
brew "luarocks"        # Lua package manager
brew "luajit"          # Lua 5.1 for image.nvim
brew "tree-sitter"
brew "graphviz"        # Graph/diagram generation
brew "d2"              # Diagram renderer (used by diagram.nvim)
brew "plantuml"        # UML/diagram renderer (used by diagram.nvim)
brew "python@3.13"     # Python for neovim provider
brew "ruby"            # Ruby for neovim provider
brew "tectonic"        # Modern LaTeX engine

# =============================================================================
# Kubernetes & Cloud
# =============================================================================
brew "kubernetes-cli"
brew "kubecolor"
brew "kustomize"       # Kubernetes config customisation
brew "helm"
brew "k9s"
brew "kind"
brew "argocd"
brew "awscli"
brew "hashicorp/tap/terraform"

# =============================================================================
# Docker
# =============================================================================
brew "docker"
brew "docker-compose"
brew "lazydocker"

# =============================================================================
# File Management & Utilities
# =============================================================================
brew "bottom"          # System monitor (btm) - used by AstroNvim
brew "btop"            # System monitor
brew "superfile"       # File manager TUI
brew "yazi"            # File manager
brew "ffmpeg"
brew "imagemagick"
brew "pandoc"
brew "chafa"           # Image viewer for terminal
brew "posting"         # API testing TUI
brew "terminal-notifier" # macOS notifications for herdr toasts (`[ui.toast] delivery = "system"`);
                         # without it herdr falls back to osascript, which cannot raise the terminal

# =============================================================================
# Database
# =============================================================================
brew "postgresql@14"

# =============================================================================
# Remote Access (Tailscale SSH) — PERSONAL-ONLY
# =============================================================================
# Deliberately skipped on work machines (./install.sh --work). Joining a
# corporate laptop to a personal WireGuard mesh, and opening an SSH ingress to
# it, is a policy problem — not merely clutter.
#
# This is the CLI daemon, NOT the `tailscale-app` cask. That distinction is
# load-bearing: the GUI variants (App Store and Standalone) *cannot* act as a
# Tailscale SSH server — only the open-source tailscaled can. The cask would
# leave this host with no ingress at all. It also runs at boot as a system
# daemon rather than only while a user is logged in, which is what a remotely
# reached machine needs.
#
# Installing it is not enough on its own — the host must be joined to the
# tailnet, which needs interactive browser auth: see "Remote access" in
# README.md. macOS Remote Login (sshd) stays OFF; tailscaled serves port 22 on
# the tailnet address only.
unless work?
  brew "tailscale"     # WireGuard mesh + Tailscale SSH; the only path in
end

# =============================================================================
# Casks (GUI Applications)
# =============================================================================
cask "ghostty"         # Terminal emulator
cask "raycast"         # Spotlight replacement
# claude-code — installed via the official installer in install.sh (curl … | bash), not Homebrew
cask "codex"           # OpenAI coding agent
cask "gcloud-cli"      # Google Cloud SDK
cask "ngrok"           # Secure tunnelling

# Personal-only — skipped on work machines (./install.sh --work)
unless work?
  cask "handy"         # Offline speech-to-text
end

# =============================================================================
# AI & Agentic Tools
# =============================================================================
brew "gemini-cli"      # Google Gemini CLI
brew "sst/tap/opencode" # AI coding assistant TUI

# =============================================================================
# Fonts
# =============================================================================
cask "font-hack-nerd-font"
cask "font-monaspice-nerd-font"
cask "font-symbols-only-nerd-font"
