#!/bin/bash
# =============================================================================
# Dotfiles Installation Script
# =============================================================================
# This script sets up a fresh macOS machine with all configurations.
# Run with: ./install.sh
# Preview changes with: ./install.sh --dry-run
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false

# =============================================================================
# Helper Functions
# =============================================================================

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

run() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    else
        "$@"
    fi
}

# =============================================================================
# Pre-flight Checks
# =============================================================================

check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        error "This script is designed for macOS only."
    fi
    success "Running on macOS"
}

parse_args() {
    for arg in "$@"; do
        case $arg in
            --dry-run)
                DRY_RUN=true
                warn "Dry-run mode enabled. No changes will be made."
                ;;
            --help|-h)
                echo "Usage: $0 [--dry-run] [--help]"
                echo ""
                echo "Options:"
                echo "  --dry-run    Preview changes without making them"
                echo "  --help       Show this help message"
                exit 0
                ;;
        esac
    done
}

# =============================================================================
# Installation Functions
# =============================================================================

install_homebrew() {
    info "Checking for Homebrew..."
    if command -v brew &> /dev/null; then
        success "Homebrew already installed"
    else
        info "Installing Homebrew..."
        run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for this session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        success "Homebrew installed"
    fi
}

install_packages() {
    info "Installing packages from Brewfile..."
    if [ -f "$SCRIPT_DIR/Brewfile" ]; then
        run brew bundle --file="$SCRIPT_DIR/Brewfile"
        success "Packages installed"
    else
        warn "Brewfile not found, skipping package installation"
    fi
}

configure_macos() {
    info "Configuring macOS settings..."

    # Faster key repeat (lower = faster)
    run defaults write NSGlobalDomain KeyRepeat -int 1
    run defaults write NSGlobalDomain InitialKeyRepeat -int 10

    # Enable full keyboard navigation (Tab through all UI controls)
    run defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

    # Disable press-and-hold for character picker (enables key repeat)
    run defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

    # Expand save panel by default
    run defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    run defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

    # Disable automatic capitalization
    run defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

    # Disable smart dashes
    run defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

    # Disable automatic period substitution
    run defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

    # Disable smart quotes
    run defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

    # Disable auto-correct
    run defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    # Raycast: Set hotkey to Command+Space
    run defaults write com.raycast.macos raycastGlobalHotkey -string "Command-49"

    success "macOS settings configured (some may require logout/restart)"
}

backup_existing() {
    info "Backing up existing configurations..."

    local files_to_backup=(
        "$HOME/.zshrc"
        "$HOME/.tmux.conf"
        "$HOME/.gitconfig"
        "$HOME/.config/nvim"
        "$HOME/.config/aerospace"
        "$HOME/.config/ghostty"
        "$HOME/.config/starship.toml"
    )

    local backup_needed=false
    for file in "${files_to_backup[@]}"; do
        if [ -e "$file" ] && [ ! -L "$file" ]; then
            backup_needed=true
            break
        fi
    done

    if [ "$backup_needed" = true ]; then
        run mkdir -p "$BACKUP_DIR"
        for file in "${files_to_backup[@]}"; do
            if [ -e "$file" ] && [ ! -L "$file" ]; then
                run cp -r "$file" "$BACKUP_DIR/"
                info "Backed up: $file"
            fi
        done
        success "Existing configs backed up to $BACKUP_DIR"
    else
        info "No existing configs to backup (or already symlinked)"
    fi
}

create_symlinks() {
    info "Creating symlinks..."

    # Ensure .config directory exists
    run mkdir -p "$HOME/.config"

    # Helper function to create a symlink
    link_file() {
        local source="$1"
        local target="$2"

        if [ ! -e "$source" ]; then
            warn "Source not found, skipping: $source"
            return
        fi

        # Remove existing file/symlink
        if [ -e "$target" ] || [ -L "$target" ]; then
            run rm -rf "$target"
        fi

        # Create parent directory if needed
        run mkdir -p "$(dirname "$target")"

        # Create symlink
        run ln -sf "$source" "$target"
        success "Linked: $target -> $source"
    }

    # Create symlinks for each config
    link_file "$SCRIPT_DIR/dotfiles/.zshrc" "$HOME/.zshrc"
    link_file "$SCRIPT_DIR/dotfiles/.tmux.conf" "$HOME/.tmux.conf"
    link_file "$SCRIPT_DIR/dotfiles/.gitconfig" "$HOME/.gitconfig"
    link_file "$SCRIPT_DIR/dotfiles/.gitignore_global" "$HOME/.gitignore_global"
    link_file "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"
    link_file "$SCRIPT_DIR/aerospace" "$HOME/.config/aerospace"
    link_file "$SCRIPT_DIR/ghostty" "$HOME/.config/ghostty"
    link_file "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
}

configure_git() {
    info "Configuring git to use global gitignore..."
    run git config --global core.excludesfile "$HOME/.gitignore_global"
    success "Git configured to use ~/.gitignore_global"
}

configure_zsh() {
    info "Configuring zsh as default shell..."

    # Check if zsh is already the default shell
    if [[ "$SHELL" == *"zsh"* ]]; then
        success "zsh is already the default shell"
    else
        # Get the path to Homebrew's zsh
        local zsh_path="/opt/homebrew/bin/zsh"
        if [[ ! -x "$zsh_path" ]]; then
            zsh_path="/bin/zsh"
        fi

        # Add to /etc/shells if not present
        if ! grep -q "$zsh_path" /etc/shells; then
            info "Adding $zsh_path to /etc/shells (requires sudo)"
            echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
        fi

        # Change default shell
        info "Setting zsh as default shell (requires password)"
        run chsh -s "$zsh_path"
        success "zsh set as default shell (restart terminal to take effect)"
    fi
}

install_tpm() {
    info "Setting up Tmux Plugin Manager (TPM)..."

    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [ -d "$tpm_dir" ]; then
        success "TPM already installed"
    else
        run git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
        success "TPM installed"
    fi

    # Install tmux plugins via TPM
    info "Installing tmux plugins..."
    if [ -x "$tpm_dir/bin/install_plugins" ]; then
        run "$tpm_dir/bin/install_plugins"
        success "Tmux plugins installed"
    else
        warn "TPM install script not found, run 'prefix + I' in tmux manually"
    fi
}

install_neovim_providers() {
    info "Installing Neovim providers and tools..."

    # Python provider + molten-nvim dependencies via uv
    if command -v uv &> /dev/null; then
        local nvim_python_dir="$HOME/.local/share/nvim/python"
        if [ ! -f "$nvim_python_dir/pyproject.toml" ]; then
            info "Creating Neovim Python project at $nvim_python_dir..."
            run uv init --no-readme "$nvim_python_dir"
        fi
        info "Installing Neovim Python packages (pynvim, molten deps, jupytext)..."
        run uv add --directory "$nvim_python_dir" \
            pynvim jupyter_client jupytext nbformat \
            cairosvg pillow ipykernel
        success "Neovim Python environment configured at $nvim_python_dir"

        # Register Jupyter kernel for molten-nvim
        info "Registering Jupyter kernel..."
        run uv run --directory "$nvim_python_dir" \
            python -m ipykernel install --user --name=python3 --display-name "Python 3"
        success "Jupyter kernel 'python3' registered"
    else
        warn "uv not found, skipping Python provider and molten setup"
    fi

    # Ruby provider
    local ruby_path="/opt/homebrew/opt/ruby/bin"
    if [ -x "$ruby_path/gem" ]; then
        run "$ruby_path/gem" install neovim
        success "Ruby provider installed"
    else
        warn "Homebrew Ruby not found, skipping Ruby provider"
    fi

    # Mermaid CLI for diagrams
    if command -v npm &> /dev/null; then
        run npm install -g @mermaid-js/mermaid-cli
        success "Mermaid CLI (mmdc) installed"
    else
        warn "npm not found, skipping mermaid-cli"
    fi
}

create_secrets_template() {
    info "Creating secrets template..."

    local secrets_example="$HOME/.secrets.example"
    if [ ! -f "$secrets_example" ]; then
        run cat > "$secrets_example" << 'EOF'
# =============================================================================
# Secrets File - Copy to ~/.secrets and fill in your values
# =============================================================================
# This file is sourced by .zshrc. Keep it out of version control!

# AI/LLM API Keys
# export OPENAI_API_KEY=""
# export ANTHROPIC_API_KEY=""

# Cloud Provider Credentials
# export AWS_ACCESS_KEY_ID=""
# export AWS_SECRET_ACCESS_KEY=""

# GitHub/GitLab Tokens
# export GITHUB_TOKEN=""
# export GITLAB_TOKEN=""

# Other secrets
# export DATABASE_URL=""
EOF
        success "Created $secrets_example"
        warn "Copy to ~/.secrets and add your actual API keys"
    else
        info "Secrets template already exists"
    fi
}

print_post_install() {
    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your terminal or run: source ~/.zshrc"
    echo "  2. In tmux, press 'prefix + I' to install tmux plugins"
    echo "  3. Open nvim and let lazy.nvim install plugins"
    echo "  4. Open any .ipynb file in nvim to verify notebook support"
    echo "     Use ',mi' to init a kernel, ',ml' to run a line"
    echo "  5. Create your secrets file:"
    echo "     cp ~/.secrets.example ~/.secrets"
    echo "     nvim ~/.secrets"
    echo ""
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}This was a dry run. No changes were made.${NC}"
        echo "Run without --dry-run to apply changes."
    fi
    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}  Dotfiles Installation${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo ""

    parse_args "$@"
    check_macos

    install_homebrew
    install_packages
    configure_macos
    backup_existing
    create_symlinks
    configure_git
    configure_zsh
    install_tpm
    install_neovim_providers
    create_secrets_template

    print_post_install
}

main "$@"
