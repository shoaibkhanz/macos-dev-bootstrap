#!/bin/bash
# =============================================================================
# Dotfiles Installation Script
# =============================================================================
# This script sets up a fresh macOS machine with all configurations.
# Run with: ./install.sh
# Preview changes with: ./install.sh --dry-run
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fail loudly on any error that escapes a `step` (pre-flight, PATH setup).
# No line number: on macOS's bash 3.2, $LINENO inside an ERR trap reports the
# line the innermost function was *defined* on, not the line that failed.
trap 'echo -e "${RED}[ERROR]${NC} Installation failed — see the error above"; exit 1' ERR

# Script directory (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
SKIP_BREW=false
WORK_MODE=false
HERDR_ONLY=false
INSTALL_CLAUDE=false

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

# Steps that failed, recorded by `step` and reported in the final summary.
FAILED_STEPS=()

# Run one install phase so that its failure cannot abort the bootstrap.
#
# The phase runs in a subshell with errexit + errtrace on, so it stops at its
# *own* first failing command (never carries on with half-built state), while
# the parent records the failure and moves to the next phase.
#
# The `set +e` around the subshell is load-bearing twice over: it stops the
# parent from dying with the phase, and it keeps the subshell out of a
# condition context — bash suppresses errexit inside a subshell used as an
# `if`/`&&`/`||` operand, even one that re-runs `set -e` itself.
#
# A phase can only publish results to later phases through the filesystem, not
# through shell state — see ensure_brew_path for the one exception (PATH).
step() {
    local label="$1" rc=0
    shift

    set +e
    (
        set -eE
        trap 'echo -e "${RED}[ERROR]${NC} ${label} failed — see the error above"' ERR
        "$@"
    )
    rc=$?
    set -e

    [ "$rc" -eq 0 ] && return 0
    FAILED_STEPS+=("$label")
    warn "Step '$label' failed (exit $rc) — continuing; see the summary at the end."
    return 0
}

# Homebrew's bin dir must be on PATH for later steps (tmux, uv, nvim, delta) to
# find their binaries. Re-applied in main after the brew steps because a fresh
# `brew shellenv` eval inside a `step` subshell dies with that subshell.
ensure_brew_path() {
    if ! command -v brew &> /dev/null && [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

# Helper: create or update a symlink (backs up existing non-symlink files first)
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

# Symlink every tracked herdr config into the live ~/.config/herdr tree.
# Shared by the full install (create_symlinks) and the --herdr fast path.
link_herdr_configs() {
    # Main config.
    link_file "$SCRIPT_DIR/herdr/config.toml" "$HOME/.config/herdr/config.toml"
    # workspace-manager plugin layouts. The plugin reads its config from
    # ~/.config/herdr/plugins/config/<plugin-id>/config.yml, so link it there.
    link_file "$SCRIPT_DIR/herdr/plugins/workspace-manager/config.yml" \
        "$HOME/.config/herdr/plugins/config/herdr-plugin-workspace-manager/config.yml"
}

# --herdr fast path: refresh only herdr config + integrations, wherever run.
update_herdr() {
    info "Updating herdr configuration from $SCRIPT_DIR/herdr..."
    run mkdir -p "$HOME/.config/herdr"
    link_herdr_configs
    configure_herdr_integrations
    success "Herdr configuration updated."
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
            --skip-brew)
                SKIP_BREW=true
                warn "Skipping Homebrew installation and packages."
                ;;
            --work)
                WORK_MODE=true
                warn "Work mode enabled. Personal-only packages will be skipped."
                ;;
            --herdr)
                HERDR_ONLY=true
                warn "Herdr-only mode: refreshing herdr config + integrations only."
                ;;
            --claude)
                INSTALL_CLAUDE=true
                warn "Claude mode: Claude/agent skills, settings, rules & commands WILL be installed (overwriting existing)."
                ;;
            --help|-h)
                echo "Usage: $0 [--dry-run] [--skip-brew] [--work] [--herdr] [--claude] [--help]"
                echo ""
                echo "Options:"
                echo "  --dry-run    Preview changes without making them"
                echo "  --skip-brew  Skip Homebrew install and brew bundle"
                echo "  --work       Skip personal-only packages (e.g. handy)"
                echo "  --herdr      Only refresh herdr config + integrations (skip everything else)"
                echo "  --claude     Install Claude/agent skills, settings, rules & commands (default: left untouched)"
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
        return
    fi

    info "Installing Homebrew..."
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} curl ...Homebrew/install/HEAD/install.sh | bash"
        return
    fi

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    success "Homebrew installed"
}

clear_cask_conflicts() {
    # Some casks (e.g. `codex`) refuse to install if a non-Homebrew binary
    # already occupies their target path — typically from a prior `npm i -g`
    # install. Move those aside so brew bundle can proceed.
    info "Checking for known cask/binary conflicts..."

    local conflicts=(
        "/opt/homebrew/bin/codex"   # cask "codex"
    )

    local found_any=false
    for path in "${conflicts[@]}"; do
        [ -e "$path" ] || [ -L "$path" ] || continue

        # If it's a symlink, check where it points; skip if Homebrew already owns it.
        if [ -L "$path" ]; then
            local target
            target="$(readlink "$path")"
            case "$target" in
                /opt/homebrew/Cellar/*|/opt/homebrew/Caskroom/*|../Cellar/*|../Caskroom/*)
                    continue
                    ;;
            esac
        fi

        if [ "$found_any" = false ]; then
            run mkdir -p "$BACKUP_DIR"
            found_any=true
        fi
        warn "Found non-Homebrew file at $path — moving aside to allow cask install"
        run mv "$path" "$BACKUP_DIR/$(basename "$path").pre-brew"
    done

    if [ "$found_any" = false ]; then
        info "No conflicts found"
    fi
}

install_packages() {
    info "Installing packages from Brewfile..."
    if [ ! -f "$SCRIPT_DIR/Brewfile" ]; then
        warn "Brewfile not found, skipping package installation"
        return
    fi

    local bundle_cmd=(brew bundle --file="$SCRIPT_DIR/Brewfile")
    if [ "$WORK_MODE" = true ]; then
        # HOMEBREW_-prefixed because brew bundle scrubs other env vars.
        bundle_cmd=(env HOMEBREW_BUNDLE_WORK=1 "${bundle_cmd[@]}")
    fi

    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} ${bundle_cmd[*]}"
        return
    fi

    # `brew bundle` is all-or-nothing: it runs one `brew fetch` for every entry
    # up front and installs *nothing* if that fetch fails (Homebrew 6:
    # Library/Homebrew/bundle/installer.rb). One unavailable cask therefore
    # leaves the machine with no tmux, no uv, no node — which is exactly how a
    # bootstrap ends up dying later with "tmux: command not found".
    if "${bundle_cmd[@]}"; then
        success "Packages installed"
        return 0
    fi

    warn "brew bundle failed as a batch — retrying the missing entries one at a time."
    install_missing_bundle_entries
}

# Ask brew what the Brewfile still wants, then install each entry on its own so
# one broken formula or cask costs exactly itself. Returns non-zero if anything
# is still missing afterwards, so the run is reported as a failed step.
install_missing_bundle_entries() {
    local missing failed=0 count kind name

    # `brew bundle check` exits 1 exactly when something is missing, which is
    # the case we care about — `|| true` keeps errexit/pipefail from killing the
    # function before it can read the list. No auto-update: the bundle run that
    # just failed already did one.
    missing="$(env HOMEBREW_NO_AUTO_UPDATE=1 \
        brew bundle check --file="$SCRIPT_DIR/Brewfile" --verbose 2>&1 |
        sed -nE 's/^.*(Tap|Formula|Cask) ([^ ]+) needs to be.*$/\1 \2/p' || true)"

    if [ -z "$missing" ]; then
        warn "brew bundle reported a failure but nothing is missing — treating as installed."
        return 0
    fi

    count="$(printf '%s\n' "$missing" | wc -l | tr -d ' ')"
    info "$count Brewfile entries still missing — installing individually..."

    # Herestring, not a pipe: the loop must run in this shell so $failed sticks.
    while read -r kind name; do
        [ -n "$name" ] || continue
        case "$kind" in
            Tap)     run brew tap "$name" ;;
            Formula) run brew install --formula "$name" ;;
            Cask)    run brew install --cask "$name" ;;
            *)       continue ;;
        esac || {
            warn "Failed to install $kind $name — skipping it."
            failed=$((failed + 1))
        }
    done <<< "$missing"

    if [ "$failed" -gt 0 ]; then
        warn "$failed of $count entries could not be installed; the rest are in place."
        warn "Fix those, then re-run 'brew bundle --file=$SCRIPT_DIR/Brewfile'."
        return 1
    fi

    success "Installed all $count entries that brew bundle skipped"
}

install_claude_code() {
    info "Installing Claude Code (official installer, not Homebrew)..."
    if command -v claude &> /dev/null; then
        success "Claude Code already installed; skipping (re-run the installer to update)"
        return
    fi
    # Anthropic's official installer — deliberately NOT the Homebrew cask.
    run bash -c "curl -fsSL https://claude.ai/install.sh | bash"
    success "Claude Code installed via official installer"
}

install_omp() {
    info "Installing omp (Oh My Pi harness)..."
    if command -v omp &> /dev/null; then
        success "omp already installed; skipping (re-run the installer to update)"
        return
    fi
    # Official omp installer — deliberately NOT Homebrew. Installs to ~/.local/bin (on PATH via .zshrc).
    run bash -c "curl -fsSL https://omp.sh/install | sh"
    success "omp installed via official installer"
}

configure_herdr_integrations() {
    info "Installing herdr agent integrations (pi, omp, claude)..."
    if ! command -v herdr &> /dev/null; then
        warn "herdr not on PATH — skipping. Once herdr is installed, run:"
        warn "  herdr integration install pi && herdr integration install omp && herdr integration install claude"
        return
    fi
    # Each install writes that agent's herdr state extension (e.g. ~/.claude/hooks/herdr-agent-state.sh).
    # Server-independent, so it's safe during a fresh bootstrap. Non-fatal: an agent not yet installed
    # (e.g. pi with no ~/.pi/agent/extensions dir) exits non-zero — warn and continue instead of
    # aborting under `set -e`.
    for agent in pi omp claude; do
        run herdr integration install "$agent" || warn "herdr integration for '$agent' skipped (is $agent installed?)"
    done
    success "herdr integrations configured (pi, omp, claude)"
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
        "$HOME/.gitignore_global"
        "$HOME/.config/nvim"
        "$HOME/.config/ghostty"
        "$HOME/.config/starship.toml"
        "$HOME/.config/lazygit"
        "$HOME/.config/marimo"
        "$HOME/.config/herdr/config.toml"
    )

    # Only back up (and thus later overwrite) Claude/agent config when opted in
    # via --claude. Otherwise leave the existing tree entirely untouched.
    if [ "$INSTALL_CLAUDE" = true ]; then
        files_to_backup+=(
            "$HOME/.claude/settings.json"
            "$HOME/.claude/rules"
            "$HOME/.claude/commands"
            "$HOME/.agents/skills"
            "$HOME/.agents/hooks"
            "$HOME/.agents/commands"
        )
    fi

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
                # Preserve path structure under BACKUP_DIR to avoid basename
                # collisions (e.g. .claude/commands vs .agents/commands).
                local rel="${file#$HOME/}"
                local dest="$BACKUP_DIR/$rel"
                run mkdir -p "$(dirname "$dest")"
                run cp -r "$file" "$dest"
                info "Backed up: $file"
            fi
        done
        success "Existing configs backed up to $BACKUP_DIR"
    else
        info "No existing configs to backup (or already symlinked)"
    fi
}

install_marimo_config() {
    info "Installing Marimo configuration..."

    local marimo_dir="$HOME/.config/marimo"

    if [ ! -d "$SCRIPT_DIR/marimo" ]; then
        warn "Marimo config not found in repo, skipping"
        return
    fi

    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} mkdir -p $marimo_dir"
        echo -e "${YELLOW}[DRY-RUN]${NC} cp marimo-code.css, marimo-vimrc -> $marimo_dir/"
        echo -e "${YELLOW}[DRY-RUN]${NC} sed s|__HOME__|$HOME|g marimo.toml -> $marimo_dir/marimo.toml"
        return
    fi

    mkdir -p "$marimo_dir"

    # Copy CSS and vimrc directly
    [ -f "$SCRIPT_DIR/marimo/marimo-code.css" ] && \
        cp "$SCRIPT_DIR/marimo/marimo-code.css" "$marimo_dir/marimo-code.css"
    [ -f "$SCRIPT_DIR/marimo/marimo-vimrc" ] && \
        cp "$SCRIPT_DIR/marimo/marimo-vimrc" "$marimo_dir/marimo-vimrc"

    # Copy marimo.toml with __HOME__ replaced by actual home directory
    sed "s|__HOME__|$HOME|g" "$SCRIPT_DIR/marimo/marimo.toml" > "$marimo_dir/marimo.toml"
    success "Marimo config installed (paths resolved for $HOME)"
}

# Symlink Claude Code + agent config (skills, hooks, commands, rules, settings).
# Opt-in via --claude so we never overwrite an existing setup by default.
link_claude_configs() {
    local skill name

    # Claude Code: agents (skills, hooks, commands)
    link_file "$SCRIPT_DIR/claude/agents/skills" "$HOME/.agents/skills"
    link_file "$SCRIPT_DIR/claude/agents/hooks" "$HOME/.agents/hooks"
    link_file "$SCRIPT_DIR/claude/agents/commands" "$HOME/.agents/commands"

    # Claude Code: rules and commands
    link_file "$SCRIPT_DIR/claude/rules" "$HOME/.claude/rules"
    link_file "$SCRIPT_DIR/claude/commands" "$HOME/.claude/commands"
    link_file "$SCRIPT_DIR/claude/settings.json" "$HOME/.claude/settings.json"

    # Claude Code: per-skill symlinks so vendored skills are discoverable
    for skill in "$SCRIPT_DIR"/claude/agents/skills/*/; do
        [ -d "$skill" ] || continue
        name="$(basename "$skill")"
        link_file "${skill%/}" "$HOME/.claude/skills/$name"
    done
}

create_symlinks() {
    info "Creating symlinks..."

    # Ensure .config directory exists
    run mkdir -p "$HOME/.config"

    # Create symlinks for each config
    link_file "$SCRIPT_DIR/dotfiles/.zshrc" "$HOME/.zshrc"
    link_file "$SCRIPT_DIR/dotfiles/.tmux.conf" "$HOME/.tmux.conf"
    link_file "$SCRIPT_DIR/dotfiles/.gitignore_global" "$HOME/.gitignore_global"
    link_file "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"
    link_file "$SCRIPT_DIR/ghostty" "$HOME/.config/ghostty"
    link_file "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
    link_file "$SCRIPT_DIR/lazygit" "$HOME/.config/lazygit"
    link_herdr_configs

    # Claude Code / agent config: opt-in only (--claude). By default we never
    # touch an existing ~/.claude or ~/.agents tree, so pulling this repo onto
    # another machine won't clobber that machine's own skills/settings.
    if [ "$INSTALL_CLAUDE" = true ]; then
        link_claude_configs
    else
        info "Skipping Claude/agent config (skills, settings, rules, commands). Pass --claude to install."
    fi
}

# Backing up and overwriting are one transaction: create_symlinks and
# install_marimo_config `rm -rf` / rewrite the very paths backup_existing
# copies aside. Running them as a single `step` means errexit stops the
# overwrite the moment a backup fails, instead of destroying configs whose
# copy never happened.
backup_and_install_configs() {
    backup_existing
    create_symlinks
    install_marimo_config
}

git_config_set() {
    # Set a global git config key only if its current value differs.
    # Keeps dry-run output minimal and avoids redundant writes.
    local key="$1"
    local value="$2"
    local current
    current="$(git config --global "$key" 2>/dev/null || true)"
    if [[ "$current" != "$value" ]]; then
        run git config --global "$key" "$value"
    fi
}

configure_git() {
    info "Configuring git globals..."
    # .gitconfig is NOT symlinked so user.name / user.email stay per-machine.
    # Everything below is set via `git config --global` so it's always correct
    # regardless of what's in ~/.gitconfig.

    git_config_set core.excludesfile "$HOME/.gitignore_global"

    # delta — pretty diffs. Only wire up if the binary is present so we don't
    # break `git log`/`git diff` on machines where --skip-brew was used.
    if command -v delta &> /dev/null; then
        git_config_set core.pager "delta"
        git_config_set interactive.diffFilter "delta --color-only"
        git_config_set delta.navigate "true"
        git_config_set delta.line-numbers "true"
        git_config_set merge.conflictstyle "zdiff3"
        success "Git configured (gitignore + delta)"
    else
        warn "delta not installed — skipping delta config (run brew bundle to install)"
        success "Git configured (gitignore only)"
    fi
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
            if [ "$DRY_RUN" = true ]; then
                echo -e "${YELLOW}[DRY-RUN]${NC} echo $zsh_path | sudo tee -a /etc/shells"
            else
                echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
            fi
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

    # TPM shells out to `tmux` for every plugin operation, so a machine where
    # brew bundle failed (or where /opt/homebrew/bin is missing from PATH) would
    # otherwise die here with "tmux: command not found". Skip the plugin install
    # and report the step as failed, so a degraded machine doesn't finish green.
    if ! command -v tmux &> /dev/null; then
        warn "tmux not found on PATH — skipping plugin install."
        warn "Fix with 'brew install tmux', then run: $tpm_dir/bin/install_plugins"
        return 1
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

        # `uv init <dir>` takes the project name from the directory, and this
        # one is called `python` — a name uv refuses to install:
        #   error: Failed to install: python-0.1.0-py3-none-any.whl
        #     Caused by: Scripts must not use the reserved name `python`
        # (uv blocks any wheel whose scripts could overwrite the interpreter).
        # The directory name stays — nvim's python3_host_prog points at
        # <dir>/.venv/bin/python3 — only the project name is forced to a safe one.
        if [ ! -f "$nvim_python_dir/pyproject.toml" ]; then
            info "Creating Neovim Python project at $nvim_python_dir..."
            run uv init --no-readme --name nvim-python "$nvim_python_dir"
        elif grep -q '^name = "python"$' "$nvim_python_dir/pyproject.toml"; then
            warn "Project in $nvim_python_dir is named 'python' (reserved) — renaming to 'nvim-python'"
            run sed -i '' 's/^name = "python"$/name = "nvim-python"/' "$nvim_python_dir/pyproject.toml"
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

    # Node.js provider
    if command -v npm &> /dev/null; then
        run npm install -g neovim
        success "Node.js provider installed"
    else
        warn "npm not found, skipping Node.js provider"
    fi

    # Ruby provider (use Homebrew Ruby, add gem bin to PATH)
    local ruby_path="/opt/homebrew/opt/ruby/bin"
    if [ -x "$ruby_path/gem" ]; then
        local gem_bin
        gem_bin="$("$ruby_path/ruby" -e 'puts Gem.user_dir')/bin"
        run "$ruby_path/gem" install --user-install neovim
        success "Ruby provider installed (gem bin: $gem_bin)"
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
    if [ -f "$secrets_example" ]; then
        info "Secrets template already exists"
        return
    fi

    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} write secrets template -> $secrets_example"
        return
    fi

    cat > "$secrets_example" << 'EOF'
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
}

# Shared by the full install and the --herdr fast path: the list of steps that
# failed, and how to recover. No-op when everything succeeded.
print_failure_summary() {
    ((${#FAILED_STEPS[@]})) || return 0

    echo -e "${YELLOW}Failed steps (everything else was still installed):${NC}"
    local failed_step
    for failed_step in "${FAILED_STEPS[@]}"; do
        echo "  - $failed_step"
    done
    echo ""
    echo "Scroll up for the [ERROR] line of each one. Fix the cause, then re-run"
    echo "./install.sh — it is idempotent, finished steps are skipped or refreshed."
    echo ""
}

print_post_install() {
    echo ""
    if ((${#FAILED_STEPS[@]})); then
        echo -e "${YELLOW}=========================================${NC}"
        echo -e "${YELLOW}  Installation finished — ${#FAILED_STEPS[@]} step(s) failed${NC}"
        echo -e "${YELLOW}=========================================${NC}"
    else
        echo -e "${GREEN}=========================================${NC}"
        echo -e "${GREEN}  Installation Complete!${NC}"
        echo -e "${GREEN}=========================================${NC}"
    fi
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
    echo "  6. Marimo AI features need API keys in ~/.secrets:"
    echo "     export ANTHROPIC_API_KEY=\"...\""
    echo "     export OPENAI_API_KEY=\"...\""
    if [ "$INSTALL_CLAUDE" = true ]; then
        echo "  * Claude/agent config was installed (--claude)."
    else
        echo "  * Claude/agent skills & settings were left untouched. Re-run with --claude to install them."
    fi
    echo ""
    print_failure_summary

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

    if [ "$HERDR_ONLY" = true ]; then
        step "herdr config" update_herdr
        if [ "$DRY_RUN" = true ]; then
            echo ""
            echo -e "${YELLOW}This was a dry run. No changes were made.${NC}"
        fi
        if ((${#FAILED_STEPS[@]})); then
            echo ""
            print_failure_summary
            exit 1
        fi
        return 0
    fi

    ensure_brew_path
    if [ "$SKIP_BREW" = false ]; then
        step "Homebrew"            install_homebrew
        ensure_brew_path
        step "cask conflicts"      clear_cask_conflicts
        step "brew bundle"         install_packages
        ensure_brew_path
    fi
    step "Claude Code"         install_claude_code
    step "omp"                 install_omp
    step "herdr integrations"  configure_herdr_integrations
    step "macOS defaults"      configure_macos
    step "backup + configs"    backup_and_install_configs
    step "git config"          configure_git
    step "default shell"       configure_zsh
    step "tmux plugins"        install_tpm
    step "neovim providers"    install_neovim_providers
    step "secrets template"    create_secrets_template

    print_post_install

    # Exit here rather than returning non-zero: `main "$@" || …` would put the
    # whole run in a condition context, and bash 3.2 (macOS /bin/bash) then
    # suppresses errexit for every subshell inside it — including `step`'s,
    # which would stop failing phases from stopping at their first bad command.
    if ((${#FAILED_STEPS[@]})); then
        exit 1
    fi
}

main "$@"
