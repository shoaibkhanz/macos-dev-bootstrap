# ============================================================================
# ZSHRC Configuration
# ============================================================================
# This file is loaded for interactive shells. It configures the shell
# environment, aliases, functions, completions, and plugins.
#
# Structure:
#   1. Instant Prompt (Powerlevel10k) - must be first
#   2. Completion System Initialisation
#   3. Environment Variables & PATH
#   4. Aliases & Functions
#   5. Tool Initialisations (zoxide, fzf, brew)
#   6. Plugin Manager (Zinit) & Plugins
#   7. Shell Options (history, keybindings, completion styling)
#   8. External Tool Integrations
# ============================================================================


# ============================================================================
# 1. POWERLEVEL10K INSTANT PROMPT
# ============================================================================
# Enable instant prompt for faster shell startup. This caches the prompt
# so it appears immediately while the rest of zshrc loads in the background.
# IMPORTANT: Must stay at the top. Any code requiring user input (passwords,
# confirmations) must go ABOVE this block.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# ============================================================================
# 2. COMPLETION SYSTEM
# ============================================================================
# Note: compinit is called AFTER fpath is fully populated (see section 6)
# This ensures all completion directories are available.
autoload -Uz compinit


# ============================================================================
# 3. ENVIRONMENT VARIABLES & PATH
# ============================================================================
# XDG Base Directory specification
export XDG_CONFIG_HOME="$HOME/.config"

# Consolidated PATH exports
# typeset -U ensures unique entries (no duplicates)
# Note: Homebrew paths are added via `brew shellenv` in section 5
typeset -U path
path=(
  "$HOME/.local/bin"           # User-installed binaries (pipx, etc.)
  "$HOME/.config/nvim"         # Neovim config scripts
  "$HOME/.cargo/bin"           # Rust/Cargo binaries
  "$HOME/go/bin"               # Go binaries
  "$HOME/.modular/bin"         # Modular/Mojo binaries
  "$HOME/.antigravity/antigravity/bin"  # Antigravity tool
  $path
)

# Library paths for compilation (needed for mkdocs-material image processing)
# Source: https://squidfunk.github.io/mkdocs-material/plugins/requirements/image-processing/
export DYLD_FALLBACK_LIBRARY_PATH="/opt/homebrew/lib:$DYLD_FALLBACK_LIBRARY_PATH"
export LDFLAGS="-L/opt/homebrew/opt/zlib/lib"
export CPPFLAGS="-I/opt/homebrew/opt/zlib/include"

# Default editors
export EDITOR="nvim"
export VISUAL="nvim"

# API Keys - loaded from separate file for security
# Edit secrets with: nvim ~/.secrets
[[ -f ~/.secrets ]] && source ~/.secrets


# ============================================================================
# 4. ALIASES & FUNCTIONS
# ============================================================================

# --- General Shortcuts ---
alias cls="clear"
alias python="python3"

# --- Config File Shortcuts ---
alias zrc="nvim ~/.zshrc"      # Edit this file
alias src="source ~/.zshrc"    # Reload this file
alias sec="nvim ~/.secrets"    # Edit secrets file
alias nv="nvim ~/.config/nvim" # Edit Neovim config
alias sshnv="nvim ~/.ssh"      # Edit SSH config
alias vi="nvim"                # Use Neovim as vi

# --- Development Tools ---
alias lz="lazygit"             # Terminal UI for git
alias op="opencode"            # OpenCode AI assistant
alias cl="claude"              # Claude CLI
alias cld="claude --dangerously-skip-permissions"  # Claude without permission prompts

# --- Python/UV (fast Python package manager) ---
ur() { uv run "$@"; }          # Run Python scripts with uv
alias urn="uv run nvim"        # Run Neovim through uv

# --- AWS ---
alias ad="awsume datascience"  # Assume AWS datascience role

# --- Kubernetes (k8s) ---
# Lazy-load kubectl completions to prevent shell hang when cluster is unreachable.
# Completions are loaded on first use of kubectl/kubecolor/k commands.
# Unalias any conflicting aliases (e.g., from previous shell state or plugins)
unalias kt kga 2>/dev/null
_kubectl_lazy_init() {
  unfunction _kubectl_lazy_init kubectl kubecolor kt 2>/dev/null
  source <(command kubectl completion zsh)
  compdef kubecolor=kubectl
  alias kt='kubecolor'  # Persist kt after lazy-load completes
}
kubectl() { _kubectl_lazy_init; command kubecolor "$@"; }
kubecolor() { _kubectl_lazy_init; command kubecolor "$@"; }
kt() { _kubectl_lazy_init; command kubecolor "$@"; }

alias eks="eksctl"                    # EKS cluster management
alias kns="kubecolor get ns"          # List namespaces
alias kp="kubecolor get po"           # List pods
kga() { kubecolor get all -n "$1"; }  # Get all resources in namespace

# Ray cluster helpers (for ML workloads)
hp() { export HEAD_POD=$(command kubectl get pods --selector=ray.io/node-type=head -o custom-columns=POD:metadata.name --no-headers); }
kpo() { command kubectl port-forward "$HEAD_POD" "$@"; }

# --- Docker ---
alias db="docker build"
alias dr="docker run"
alias dp="docker push"

# --- File Listing (eza - modern ls replacement) ---
alias ls='eza --long --git -a --header --group'
alias tree='eza --tree --level=2 --long -a --header --git'
alias ll='eza --long --git --header --group --time-style=long-iso'
alias la='eza --long --git --all --header --group --time-style=long-iso'
alias l.='eza --long --git --header --group --time-style=long-iso .'
alias lsr='eza --long --git --header --group --time-style=long-iso --recurse'

# --- Tmux (terminal multiplexer) ---
if [[ -x "$(command -v tmux)" ]]; then
  alias tm="tmux"
  alias tmc="nvim ~/.tmux.conf"       # Edit tmux config
  alias tmka="tmux kill-session"      # Kill current session
  alias tml="tmux list-sessions"      # List all sessions
  tmk() { tmux kill-session -t "$1"; }  # Kill named session
  tma() { tmux attach -t "$1"; }        # Attach to named session
  tmn() { tmux new -s "$1"; }           # Create new named session
fi

# --- Git ---
if [[ -x "$(command -v git)" ]]; then
  # Basic commands
  alias g='git'
  alias ga='git add'
  alias gc='git commit'
  alias gcm='git commit -m'
  alias gd='git diff'
  alias gds='git diff --staged'
  alias gl='git log'
  alias gpl='git pull'
  alias gps='git push'
  alias gpf='git push --force-with-lease'  # Safe force push
  alias gr='git remote'
  alias grv='git remote -v'
  alias gs='git status'

  # Branch commands
  alias gb='git branch'
  alias gba='git branch -a'            # All branches (local + remote)
  alias gbd='git branch -d'            # Delete branch (safe)
  alias gbD='git branch -D'            # Delete branch (force)
  alias gbm='git branch -m'            # Rename branch
  alias gbn='git branch --no-merged'   # Branches not yet merged
  alias gbo='git branch --remote --verbose'
  alias gbs='git show-branch'

  # Other commands
  alias gch='git cherry'
  alias gcl='git clone'
  alias gco='git checkout'
  alias gcp='git cherry-pick'
  alias gcv='git covert'
  alias gdt='git difftool'
  alias glg='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit --date=relative'
fi


# ============================================================================
# 5. TOOL INITIALISATIONS
# ============================================================================

# Zoxide - smarter cd command (tracks frequently used directories)
# Usage: cd <partial-path> will jump to most frequently used match
(( $+commands[zoxide] )) && eval "$(zoxide init --cmd cd zsh)"

# Homebrew shell environment (sets up brew paths and environment)
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# FZF - fuzzy finder integration
# Enables Ctrl+R for history search, Ctrl+T for file search
(( $+commands[fzf] )) && source <(fzf --zsh)


# ============================================================================
# 6. PLUGIN MANAGER (ZINIT) & PLUGINS
# ============================================================================

# Zinit installation directory
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Auto-install Zinit if not present
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Load Zinit
source "${ZINIT_HOME}/zinit.zsh"

# --- Theme ---
# Powerlevel10k - fast, flexible prompt theme
zinit ice depth=1; zinit light romkatv/powerlevel10k

# --- Plugins ---
zinit light zsh-users/zsh-syntax-highlighting  # Command syntax highlighting
zinit light zsh-users/zsh-completions          # Additional completions
zinit light zsh-users/zsh-autosuggestions      # Fish-like autosuggestions
zinit light Aloxaf/fzf-tab                     # FZF-powered tab completion

# --- Oh-My-Zsh Snippets ---
# These provide additional aliases and completions from Oh-My-Zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo              # Press ESC twice to add sudo
zinit snippet OMZP::aws
# zinit snippet OMZP::kubectl  # Disabled: using custom lazy-load setup instead (see Kubernetes section)
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found # Suggests package to install for unknown commands

# Add all completion directories to fpath BEFORE compinit
fpath+=(
  "${ZINIT_HOME}/plugins/zsh-users---zsh-completions/src"
  ~/.zfunc
  ~/.docker/completions
)

# Initialise completion system (after all fpath additions)
# -C flag uses cached completions (regenerate with: rm ~/.zcompdump && compinit)
compinit -C


# ============================================================================
# 7. SHELL OPTIONS
# ============================================================================

# --- Keybindings ---
bindkey -e                          # Use Emacs-style keybindings
bindkey '^p' history-search-backward  # Ctrl+P: search history backward
bindkey '^n' history-search-forward   # Ctrl+N: search history forward
bindkey '^[w' kill-region             # Alt+W: kill region

# --- History ---
HISTSIZE=10000                      # Commands to keep in memory
HISTFILE=~/.zsh_history             # History file location
SAVEHIST=$HISTSIZE                  # Commands to save to file
HISTDUP=erase                       # Erase duplicates
setopt appendhistory                # Append to history file
setopt sharehistory                 # Share history between sessions
setopt hist_ignore_space            # Ignore commands starting with space
setopt hist_ignore_all_dups         # Remove older duplicate entries
setopt hist_save_no_dups            # Don't save duplicates
setopt hist_ignore_dups             # Ignore consecutive duplicates
setopt hist_find_no_dups            # Don't show duplicates when searching

# --- Completion Behaviour ---
setopt AUTO_MENU                    # Show completion menu on tab
setopt AUTO_LIST                    # List choices on ambiguous completion
setopt AUTO_PARAM_SLASH             # Add trailing slash to directories

# --- Completion Styling ---
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # Case-insensitive matching
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Coloured completions
zstyle ':completion:*' menu select                       # Menu selection
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Replay zinit completions (required after loading plugins)
zinit cdreplay -q


# ============================================================================
# 8. EXTERNAL TOOL INTEGRATIONS
# ============================================================================

# Powerlevel10k configuration
# Run `p10k configure` to customise, or edit ~/.p10k.zsh directly
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Rust/Cargo environment
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"


# Modular/Mojo shell completions
(( $+commands[magic] )) && eval "$(magic completion --shell zsh)"

# 1Password CLI plugins (SSH agent, etc.)
[[ -f ~/.config/op/plugins.sh ]] && source ~/.config/op/plugins.sh

# iTerm2 shell integration (enables features like cmd+click to open files)
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"


# WasmEdge runtime environment
[[ -f "$HOME/.wasmedge/env" ]] && source "$HOME/.wasmedge/env"

# UV (Python package manager) shell completions
(( $+commands[uv] )) && eval "$(uv generate-shell-completion zsh)"
(( $+commands[uvx] )) && eval "$(uvx --generate-shell-completion zsh)"

# Custom UV completion: autocomplete .py files for `uv run`
if (( $+commands[uv] )); then
  _uv_run_mod() {
    if [[ "$words[2]" == "run" && "$words[CURRENT]" != -* ]]; then
      _arguments '*:filename:_files -g "*.py"'
    else
      _uv "$@"
    fi
  }
  compdef _uv_run_mod uv
fi
