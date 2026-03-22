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
# Modular alias files live in dotfiles/aliases/ alongside this .zshrc.
# When .zshrc is symlinked (via install.sh), ${(%):-%N}:A resolves through
# the symlink to the repo directory so the alias files are found automatically.
_zshrc_aliases="${${(%):-%N}:A:h}/aliases"
if [[ -d "$_zshrc_aliases" ]]; then
  for _f in "$_zshrc_aliases"/*.zsh(N); do source "$_f"; done
  unset _f
fi
unset _zshrc_aliases


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
# zinit snippet OMZP::git  # Disabled: using custom aliases in aliases/git_aliases.zsh
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
