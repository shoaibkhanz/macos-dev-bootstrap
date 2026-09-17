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
# Components requested by --only / its shorthands (--skills, --herdr). Empty
# means a full install.
ONLY_TARGETS=()
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
    # herdr-radar settings. `follow_appearance = false` lives here and is load
    # bearing: at its default the plugin drives `[theme] name` on every desktop
    # light/dark flip, and it writes config.toml with temp-file + rename, which
    # REPLACES the symlink above with a detached copy (it did exactly that on
    # 2026-09-16, silently reverting this repo to a bystander). Edit this file
    # by hand, NOT through the plugin's prefix+, popup: the popup writes the
    # live path the same way, so the link detaches and the next `--herdr` run
    # discards the edit. Its `view-native` and `--rows-off` actions rewrite
    # config.toml too — after either, re-link with `./install.sh --herdr`.
    link_file "$SCRIPT_DIR/herdr/plugins/radar/config.toml" \
        "$HOME/.config/herdr/plugins/config/hhdebb.herdr-radar/config.toml"
}

# `--only herdr` in two halves, because they fail for unrelated reasons.
#
# This half overwrites live config, so it runs inside the backup transaction
# with every other overwriting component.
link_herdr_tree() {
    info "Updating herdr configuration from $SCRIPT_DIR/herdr..."
    run mkdir -p "$HOME/.config/herdr"
    link_herdr_configs
    success "Herdr configs linked."
}

# The other half: plugin installs and integration registration, both of which
# talk to the network. It gets its own step (see component_followup) so a
# GitHub hiccup is reported on its own instead of aborting the shared
# transaction and taking every later component's links down with it.
update_herdr_plugins() {
    install_herdr_plugins
    configure_herdr_integrations
    success "Herdr plugins and integrations updated."
}

# =============================================================================
# Targeted Installs (--only)
# =============================================================================

# Every component a targeted run can install, as "<name>|<step label>|<function>".
#
# The registry order is the order a composed --only run applies them, and it
# mirrors the full install's ordering so the same dependencies hold: brew
# before anything that needs its binaries, dotfiles (which links
# herdr/config.toml) before the herdr plugins its keybinds address, skills
# before the wider Claude config that also links them.
#
# Adding a component here is enough — parse_args, --help and the runner all
# read this list.
INSTALL_COMPONENTS=(
    "brew|Homebrew packages|install_brew_stack"
    "claude-code|Claude Code CLI|install_claude_code"
    "omp|omp|install_omp"
    "macos|macOS defaults|configure_macos"
    "dotfiles|dotfile symlinks|link_dotfiles"
    "herdr|herdr configs|link_herdr_tree"
    "skills|agent skill symlinks|link_agent_skills"
    "claude|Claude/agent config|link_claude_configs"
    "opencode|opencode config|link_opencode_configs"
    "marimo|marimo config|install_marimo_config"
    "git|git config|configure_git"
    "shell|default shell + non-interactive PATH|configure_shell"
    "tmux|tmux plugins|install_tpm"
    "nvim|neovim providers|install_neovim_providers"
    "secrets|secrets template|create_secrets_template"
)

# One line of --help per component. Kept apart from the registry so the
# registry stays a plain three-field table.
component_help() {
    case $1 in
        brew)        echo "Homebrew itself, cask conflicts and the whole Brewfile" ;;
        claude-code) echo "the Claude Code CLI (npm)" ;;
        omp)         echo "the omp CLI" ;;
        macos)       echo "macOS system defaults" ;;
        dotfiles)    echo "zshrc, tmux.conf, nvim, ghostty, starship, lazygit, herdr configs" ;;
        herdr)       echo "herdr config.toml, plugin configs, plugins, integrations" ;;
        skills)      echo "vendored agent skills -> ~/.claude/skills + ~/.agents/skills, stale links pruned" ;;
        claude)      echo "skills, plus hooks, commands, rules and settings.json" ;;
        opencode)    echo "opencode agents, prompts, docs and Obsidian skills" ;;
        marimo)      echo "marimo notebook config" ;;
        git)         echo "global git config and delta setup" ;;
        shell)       echo "zsh as default shell, plus ~/.zshenv PATH (personal only)" ;;
        tmux)        echo "tpm and the tmux plugins" ;;
        nvim)        echo "neovim python/node providers and the uv-managed host venv" ;;
        secrets)     echo "the ~/.secrets template" ;;
        *)           echo "" ;;
    esac
}

# Append a comma- or space-separated component list to ONLY_TARGETS, rejecting
# names the registry does not know and dropping duplicates (so `--skills
# --only skills` runs the component once).
add_only_targets() {
    local raw="$1" name entry known

    for name in $(printf '%s' "$raw" | tr ',' ' '); do
        known=false
        for entry in "${INSTALL_COMPONENTS[@]}"; do
            if [ "$name" = "${entry%%|*}" ]; then
                known=true
                break
            fi
        done
        if [ "$known" = false ]; then
            error "Unknown component: $name. Run $0 --help for the list."
        fi
        target_requested "$name" || ONLY_TARGETS+=("$name")
    done
}

target_requested() {
    local t
    for t in ${ONLY_TARGETS[@]+"${ONLY_TARGETS[@]}"}; do
        [ "$t" = "$1" ] && return 0
    done
    return 1
}

# Components that overwrite live config — link_file `rm -rf`s its target, and
# install_marimo_config rewrites its files in place. Every one of them must run
# behind backup_existing, inside the same step, so a failed backup stops the
# overwrite (the transaction rule backup_and_install_configs states for the
# full install).
component_overwrites_config() {
    case $1 in
        dotfiles|herdr|skills|claude|opencode|marimo) return 0 ;;
        *) return 1 ;;
    esac
}

# Which overwriting components this run targets, for the step label.
targeted_overwriting_components() {
    local entry name out=""
    for entry in "${INSTALL_COMPONENTS[@]}"; do
        name="${entry%%|*}"
        target_requested "$name" || continue
        component_overwrites_config "$name" || continue
        out="$out${out:+, }$name"
    done
    printf '%s' "$out"
}

# backup_existing plus every targeted overwriting component, as one step.
#
# They run together rather than one step each because `step` deliberately keeps
# going after a failure: a backup in its own step could fail and the links
# would still be written. In here, the step's errexit stops at the backup.
run_targeted_config_components() {
    local entry name fn

    backup_existing

    for entry in "${INSTALL_COMPONENTS[@]}"; do
        name="${entry%%|*}"
        target_requested "$name" || continue
        component_overwrites_config "$name" || continue

        # `claude` links the skills itself; asking for both would re-link every
        # skill twice for no effect.
        if [ "$name" = skills ] && target_requested claude; then
            continue
        fi

        fn="${entry##*|}"
        "$fn"
    done
}

# Work a component does *after* the overwrite transaction, as
# "<function>|<step label>", or nothing.
#
# This is for work that fails for reasons unrelated to the config it follows —
# network calls, mostly. Keeping it out of the shared transaction means a
# GitHub outage installing herdr plugins no longer aborts that step and skips
# every component queued behind it.
component_followup() {
    case $1 in
        herdr) printf 'update_herdr_plugins|herdr plugins + integrations' ;;
        *)     printf '' ;;
    esac
}

run_targeted_followups() {
    local entry name followup

    for entry in "${INSTALL_COMPONENTS[@]}"; do
        name="${entry%%|*}"
        target_requested "$name" || continue

        followup="$(component_followup "$name")"
        [ -n "$followup" ] || continue

        step "${followup#*|}" "${followup%%|*}"
    done
}

# Run just the requested components, in registry order, then report exactly
# like a full install does.
run_only_targets() {
    local entry name label fn configs_done=false failed_before

    for entry in "${INSTALL_COMPONENTS[@]}"; do
        name="${entry%%|*}"
        target_requested "$name" || continue

        # All the overwriting components go in one backup-first step, taken at
        # the position of the first of them, with any follow-up work dispatched
        # as its own step right after. That only ever moves an overwriting
        # component earlier relative to a non-overwriting one, and the single
        # ordering that matters — herdr's configs before the plugins whose
        # actions they bind — is preserved by the follow-up coming second.
        if component_overwrites_config "$name"; then
            if [ "$configs_done" = false ]; then
                configs_done=true

                # `step` always returns 0, so the transaction's outcome has to
                # be read off FAILED_STEPS. A follow-up MUST NOT run over a
                # failed transaction: if the backup failed, the configs were
                # never linked, and install_herdr_plugins would then let the
                # radar plugin write its sidebar block into whatever detached
                # config.toml is still live — the file we just failed to copy
                # aside. The pre-split update_herdr got this for free by
                # sharing one errexit subshell.
                failed_before=${#FAILED_STEPS[@]}
                step "backup + $(targeted_overwriting_components)" \
                    run_targeted_config_components
                if [ "${#FAILED_STEPS[@]}" -eq "$failed_before" ]; then
                    run_targeted_followups
                else
                    warn "Skipping follow-up work: the config step above failed."
                fi
            fi
            continue
        fi

        label="${entry#*|}"
        label="${label%%|*}"
        fn="${entry##*|}"
        step "$label" "$fn"

        # PATH has to be re-established out here: a `brew shellenv` eval inside
        # the step above died with that subshell, and later components (tmux,
        # uv, nvim, delta) need brew's bin dir. Same reason main interleaves it
        # between its brew steps.
        if [ "$name" = brew ]; then
            ensure_brew_path
        fi
    done
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
    while [ $# -gt 0 ]; do
        case $1 in
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
            --only)
                [ $# -ge 2 ] || error "--only needs a component list, e.g. --only skills. See --help."
                add_only_targets "$2"
                shift
                ;;
            --only=*)
                add_only_targets "${1#--only=}"
                ;;
            --skills)
                add_only_targets skills
                ;;
            --herdr)
                add_only_targets herdr
                ;;
            --claude)
                INSTALL_CLAUDE=true
                warn "Claude mode: Claude/agent skills, settings, rules & commands WILL be installed (overwriting existing)."
                ;;
            --help|-h)
                print_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1. See --help."
                ;;
        esac
        shift
    done

    if ((${#ONLY_TARGETS[@]})); then
        warn "Targeted run: ${ONLY_TARGETS[*]} — nothing else will be touched."
    fi
}

print_usage() {
    local entry
    echo "Usage: $0 [--dry-run] [--skip-brew] [--work] [--claude]"
    echo "       $0 --only <component>[,<component>...] [--dry-run]"
    echo "       $0 --skills | --herdr        (shorthands for --only skills / --only herdr)"
    echo ""
    echo "Options:"
    echo "  --dry-run    Preview changes without making them"
    echo "  --skip-brew  Skip Homebrew install and brew bundle"
    echo "  --work       Skip personal-only packages (e.g. handy)"
    echo "  --claude     Install Claude/agent skills, settings, rules & commands (default: left untouched)"
    echo "  --only       Install only the named components, in dependency order,"
    echo "               and skip the rest of the bootstrap. Repeatable."
    echo "  --help       Show this help message"
    echo ""
    echo "Components for --only:"
    for entry in "${INSTALL_COMPONENTS[@]}"; do
        printf '  %-11s %s\n' "${entry%%|*}" "$(component_help "${entry%%|*}")"
    done
    echo ""
    echo "Examples:"
    echo "  $0 --skills                 # re-link vendored agent skills, prune stale links"
    echo "  $0 --only skills,claude     # skills plus the rest of the Claude/agent config"
    echo "  $0 --only dotfiles --dry-run"
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

# The whole brew phase as one `--only brew` component: install Homebrew, clear
# the cask conflicts a fresh machine trips over, then run the Brewfile. Each
# ensure_brew_path is needed for the same reason it is in main — a `brew
# shellenv` eval cannot escape the step subshell it ran in.
install_brew_stack() {
    install_homebrew
    ensure_brew_path
    clear_cask_conflicts
    install_packages
    ensure_brew_path
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
    local -a bundle_env=(HOMEBREW_NO_AUTO_UPDATE=1)

    # HOMEBREW_BUNDLE_WORK must be set here too, not just on the batch run.
    # `brew bundle check` re-evaluates the Brewfile, so without it `work?`
    # returns false and every personal-only entry is reported as "missing" —
    # and this function would then install, on a work machine, exactly what
    # --work exists to keep off it (tailscale, handy).
    if [ "$WORK_MODE" = true ]; then
        bundle_env+=(HOMEBREW_BUNDLE_WORK=1)
    fi

    # `brew bundle check` exits 1 exactly when something is missing, which is
    # the case we care about — `|| true` keeps errexit/pipefail from killing the
    # function before it can read the list. No auto-update: the bundle run that
    # just failed already did one.
    missing="$(env "${bundle_env[@]}" \
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

# Every herdr plugin that herdr/config.toml binds a key to, as
# "<plugin id>|<owner/repo>". The id is what config.toml's plugin_action
# commands address (e.g. `herdr-nav-plus.left`) and what `herdr plugin list`
# prints; it is NOT always the repo name — herdr-active-agent-jump installs as
# `active-agent.jump`. Keep this list and the [[keys.command]] entries in
# herdr/config.toml in sync: a binding whose plugin is missing is a dead key
# (the action resolves to `plugin_not_found` and nothing happens).
HERDR_PLUGINS=(
    "herdr-nav-plus|shoaibkhanz/herdr-nav-plus"
    "active-agent.jump|shoaibkhanz/herdr-active-agent-jump"
    "attention.jump|milkyskies/herdr-attention"
    "herdr-plugin-workspace-manager|razajamil/herdr-plugin-workspace-manager"
    # Bound to prefix+f / prefix+comma. The `# >>> herdr-radar sidebar block`
    # in herdr/config.toml is committed, so a fresh bootstrap writes nothing:
    # its [[build]] step calls apply(), which refuses with `foreign-table`
    # because [theme.custom] sits outside the plugin's markers, and returns
    # before touching the file — the symlink survives. That refusal is not a
    # nuisance, it is the guard; see the warning above [theme.custom] in
    # herdr/config.toml before touching that block.
    "hhdebb.herdr-radar|hhdebb/herdr-radar"
)

install_herdr_plugins() {
    info "Installing herdr plugins (ctrl+hjkl nav, agent jumps, workspace layouts)..."
    if ! command -v herdr &> /dev/null; then
        warn "herdr not on PATH — skipping. Once herdr is installed, run: $SCRIPT_DIR/install.sh --herdr"
        return
    fi
    # nav-plus and both jump plugins run their actions with `node`. A missing
    # node installs fine and only fails at keypress time, so flag it here.
    command -v node &> /dev/null || warn "node not on PATH — herdr plugin actions need it (brew install node)"

    local installed
    installed="$(herdr plugin list 2> /dev/null || true)"

    local entry id repo
    for entry in "${HERDR_PLUGINS[@]}"; do
        id="${entry%%|*}"
        repo="${entry##*|}"
        # A locally linked checkout (`herdr plugin link`, for plugin dev) wins:
        # installing from GitHub would replace it with a fixed commit.
        if printf '%s\n' "$installed" | grep -q "^- $id .*\[local:"; then
            info "herdr plugin '$id' is linked from a local checkout — leaving it alone"
            continue
        fi
        # Reinstall unconditionally: it is idempotent (prints "replaces: ...")
        # and server-independent, so it doubles as the update path.
        run herdr plugin install "$repo" --yes \
            || warn "herdr plugin '$id' ($repo) failed — keys bound to $id.* will do nothing"
    done
    success "herdr plugins installed"
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

    # Faster key repeat. Both are counts of 1/60s ticks, and both go below what
    # System Settings > Keyboard offers (its fastest is KeyRepeat 2 / 33ms and
    # InitialKeyRepeat 15 / 250ms):
    #   KeyRepeat 1         -> 16.7ms between repeats
    #   InitialKeyRepeat 10 -> 167ms before the first repeat
    # These are the floors, not arbitrary lows: 0 is ignored, not faster.
    run defaults write NSGlobalDomain KeyRepeat -int 1
    run defaults write NSGlobalDomain InitialKeyRepeat -int 10

    # Enable full keyboard navigation (Tab through all UI controls)
    run defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

    # Disable press-and-hold for the diacritic picker. This is the gate: with
    # press-and-hold on, held keys open the character popover instead of
    # repeating, and the two values above appear to do nothing.
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

    # No `killall cfprefsd` here: HIToolbox reads the keyboard values once per
    # app at launch, so flushing the prefs daemon does not re-rate a running
    # app, and killing it right after these writes risks dropping them.
    success "macOS settings configured"
    warn "Keyboard: key repeat needs a REBOOT (log out at minimum) — until then"
    warn "  every already-running app keeps the key repeat rate it launched with."
}

# Copy aside every live config the components about to run will overwrite.
#
# A full install backs up the lot. A targeted (--only) run backs up exactly
# what its components write, so the backup directory never suggests a file was
# touched when it was not.
backup_existing() {
    info "Backing up existing configurations..."

    local full_run=true
    ((${#ONLY_TARGETS[@]})) && full_run=false

    local files_to_backup=()

    if [ "$full_run" = true ] || target_requested dotfiles; then
        files_to_backup+=(
            "$HOME/.zshrc"
            "$HOME/.tmux.conf"
            "$HOME/.gitignore_global"
            "$HOME/.config/nvim"
            "$HOME/.config/ghostty"
            "$HOME/.config/starship.toml"
            "$HOME/.config/lazygit"
        )
    fi

    if [ "$full_run" = true ] || target_requested marimo; then
        files_to_backup+=("$HOME/.config/marimo")
    fi

    # Every path link_herdr_configs writes, linked by both dotfiles (which
    # calls it) and herdr. Worth backing up even though these are normally
    # symlinks: the radar plugin rewrites its config with temp-file + rename,
    # which leaves a detached real file where our link was (it did exactly that
    # on 2026-09-16), and link_file would then delete the edits in it.
    if [ "$full_run" = true ] || target_requested dotfiles || target_requested herdr; then
        files_to_backup+=(
            "$HOME/.config/herdr/config.toml"
            "$HOME/.config/herdr/plugins/config/herdr-plugin-workspace-manager/config.yml"
            "$HOME/.config/herdr/plugins/config/hhdebb.herdr-radar/config.toml"
        )
    fi

    # Claude/agent config is only backed up — and so only overwritten — when
    # opted into with --claude, or named by a targeted run. Otherwise the
    # existing tree is left entirely untouched.
    local skill name
    if [ "$INSTALL_CLAUDE" = true ] || target_requested claude || target_requested skills; then
        files_to_backup+=("$HOME/.agents/skills")
        # link_agent_skills rm -rf's each ~/.claude/skills/<name> before
        # relinking it. Those are normally our own symlinks, which the copy
        # loop below skips — but a real directory does turn up there (a plugin
        # install, or a stale copy of one of ours, as three plannotator skills
        # were in 2026-08-23), and that one is worth keeping.
        for skill in "$SCRIPT_DIR"/claude/agents/skills/*/; do
            [ -d "$skill" ] || continue
            name="$(basename "$skill")"
            files_to_backup+=("$HOME/.claude/skills/$name")
        done
    fi

    if [ "$INSTALL_CLAUDE" = true ] || target_requested claude; then
        files_to_backup+=(
            "$HOME/.claude/settings.json"
            "$HOME/.claude/rules"
            "$HOME/.claude/commands"
            "$HOME/.agents/hooks"
            "$HOME/.agents/commands"
        )
    fi

    # link_opencode_configs rm -rf's these, so they belong in the same
    # transaction as everything else it overwrites. Listed per path rather than
    # as ~/.config/opencode, because cp -r on the directory would drag
    # node_modules and the plugin runtime into every backup.
    if [ "$INSTALL_CLAUDE" = true ] || target_requested opencode; then
        local oc="$HOME/.config/opencode"
        files_to_backup+=(
            "$oc/agent/obsidian.md"
            "$oc/agent/ml-agent.md"
            "$oc/prompts/obsidian-context.txt"
            "$oc/test-system.sh"
            "$oc/CHEAT_SHEET.md"
            "$oc/FIRST_COMMANDS.txt"
            "$oc/OBSIDIAN_AGENT_README.md"
            "$oc/PERMISSIONS_NOTE.md"
            "$oc/QUICK_START.md"
            "$oc/skill/today-note"
            "$oc/skill/task-review"
            "$oc/skill/research-note"
            "$oc/skill/blog-draft"
        )
    fi

    # No paths in scope: nothing to copy, and `"${files_to_backup[@]}"` on an
    # empty array is an unbound-variable error under `set -u` in bash 3.2.
    ((${#files_to_backup[@]})) || {
        info "Nothing in scope to back up"
        return 0
    }

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

# Symlink every vendored skill so both harness layouts find it: Claude Code
# reads ~/.claude/skills one entry per skill, everything else reads the tree as
# a whole at ~/.agents/skills.
#
# `npx skills@latest add …` is NOT the way to refresh these. It writes a
# separate project-level install (.agents/skills/ + skills-lock.json at the
# repo root) and leaves the vendored tree alone; run it against
# ~/.claude/skills and it writes through these symlinks into the repo. Sync
# upstream into claude/agents/skills/ from a scratch clone instead, then re-run
# `./install.sh --skills`. See claude/SKILLS_CLEANUP.md.
link_agent_skills() {
    local skill name link target

    info "Linking agent skills from $SCRIPT_DIR/claude/agents/skills..."
    link_file "$SCRIPT_DIR/claude/agents/skills" "$HOME/.agents/skills"

    # Per-skill symlinks so vendored skills are discoverable by Claude Code.
    for skill in "$SCRIPT_DIR"/claude/agents/skills/*/; do
        [ -d "$skill" ] || continue
        name="$(basename "$skill")"
        link_file "${skill%/}" "$HOME/.claude/skills/$name"
    done

    # Drop links left behind by a skill this repo renamed or dropped — and by a
    # deleted worktree of it, which is how ~/.claude/skills ended up holding 38
    # dead links once already. Only dangling links pointing at *some* copy of
    # this layout go: a plugin-installed skill directory, `learned/` and the
    # `plaud-*` set are not ours to prune.
    for link in "$HOME"/.claude/skills/*; do
        [ -L "$link" ] || continue
        [ -e "$link" ] && continue
        target="$(readlink "$link")"
        case "$target" in
            */claude/agents/skills/*)
                run rm -f "$link"
                warn "Pruned dead skill link: $(basename "$link") -> $target"
                ;;
        esac
    done

    success "Agent skills linked."
}

# Symlink Claude Code + agent config (skills, hooks, commands, rules, settings).
# Opt-in via --claude so we never overwrite an existing setup by default.
link_claude_configs() {
    link_agent_skills

    # Claude Code: agents (hooks, commands)
    link_file "$SCRIPT_DIR/claude/agents/hooks" "$HOME/.agents/hooks"
    link_file "$SCRIPT_DIR/claude/agents/commands" "$HOME/.agents/commands"

    # Claude Code: rules and commands
    link_file "$SCRIPT_DIR/claude/rules" "$HOME/.claude/rules"
    link_file "$SCRIPT_DIR/claude/commands" "$HOME/.claude/commands"
    link_file "$SCRIPT_DIR/claude/settings.json" "$HOME/.claude/settings.json"
}

# The live ~/.config/opencode tree is not ours to own: it holds node_modules,
# bun.lock, tui.json, plugins and the plannotator commands, none of which are in
# this repo. link_file rm -rf's its target, so a directory-level link would
# delete all of that. Link per file instead.
#
# opencode.jsonc is deliberately absent. opencode migrated keybinds and the tui
# block out of it into ~/.config/opencode/tui.json and left an
# opencode.jsonc.tui-migration.bak beside it, so the copy in this repo is
# pre-migration. Linking it would put deprecated keys back.
link_opencode_configs() {
    local oc="$HOME/.config/opencode"

    link_file "$SCRIPT_DIR/opencode/agent/obsidian.md"           "$oc/agent/obsidian.md"
    link_file "$SCRIPT_DIR/opencode/agent/ml-agent.md"           "$oc/agent/ml-agent.md"
    link_file "$SCRIPT_DIR/opencode/prompts/obsidian-context.txt" "$oc/prompts/obsidian-context.txt"
    link_file "$SCRIPT_DIR/opencode/test-system.sh"              "$oc/test-system.sh"

    local doc
    for doc in CHEAT_SHEET.md FIRST_COMMANDS.txt OBSIDIAN_AGENT_README.md \
               PERMISSIONS_NOTE.md QUICK_START.md; do
        link_file "$SCRIPT_DIR/opencode/$doc" "$oc/$doc"
    done

    # The four Obsidian skills are byte-identical to claude/agents/commands/<name>,
    # so link them from there rather than keeping a third copy of each.
    local skill
    for skill in today-note task-review research-note blog-draft; do
        link_file "$SCRIPT_DIR/claude/agents/commands/$skill" "$oc/skill/$skill"
    done
}

# Shell, editor and terminal configs — everything under the repo that is not
# agent config. Shared by the full install and `--only dotfiles`.
link_dotfiles() {
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
}

create_symlinks() {
    link_dotfiles

    # Claude Code / agent config: opt-in only (--claude). By default we never
    # touch an existing ~/.claude, ~/.agents or ~/.config/opencode tree, so
    # pulling this repo onto another machine won't clobber that machine's own
    # skills/settings. `--only claude` / `--only skills` install it directly.
    if [ "$INSTALL_CLAUDE" = true ]; then
        link_claude_configs
        link_opencode_configs
    else
        info "Skipping Claude/agent config (skills, settings, rules, commands, opencode agent). Pass --claude to install."
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

# Shell ownership as one `--only shell` component. configure_noninteractive_path
# no-ops itself under --work.
configure_shell() {
    configure_zsh
    configure_noninteractive_path
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

# Put Homebrew's bin dirs on the NON-INTERACTIVE PATH, via ~/.zshenv.
#
# `ssh host 'cmd'` runs zsh non-login and non-interactive, so only /etc/zshenv
# and ~/.zshenv are read: /etc/zprofile — and with it path_helper — never runs,
# and /opt/homebrew/bin is absent. Anything probing this host over exactly that
# shell then sees a bare PATH. Tailscale SSH serves commands through it, so
# without this a remote `ssh host 'herdr …'` cannot find herdr or tmux and
# silently falls back to a plain login shell. ~/.zshrc is the wrong place:
# non-interactive shells never read it.
#
# Personal-only: it exists solely to make this host usable over the tailnet,
# so --work skips it and leaves a work machine's shell environment untouched.
configure_noninteractive_path() {
    if [ "$WORK_MODE" = true ]; then
        info "Work mode — skipping non-interactive PATH (remote access is personal-only)"
        return 0
    fi

    info "Adding Homebrew to the non-interactive PATH (~/.zshenv)..."

    local zshenv="$HOME/.zshenv"
    if [ -f "$zshenv" ] && grep -q '/opt/homebrew/bin' "$zshenv"; then
        success "Homebrew already on the non-interactive PATH"
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} append Homebrew PATH guard to $zshenv"
        return 0
    fi

    cat >> "$zshenv" <<'ZSHENV'

# Homebrew on the NON-INTERACTIVE PATH — `ssh host 'cmd'` reads only
# /etc/zshenv and this file, so path_helper never runs. Guarded so login
# shells don't collect a duplicate entry. Added by macos-dev-bootstrap.
case ":$PATH:" in
  *":/opt/homebrew/bin:"*) ;;
  *) export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH" ;;
esac
ZSHENV
    success "Homebrew added to the non-interactive PATH"
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

# Write the pyproject.toml for nvim's python3 host venv (deps come from
# `uv add` right after). requires-python is deliberately loose: the venv
# tracks whatever interpreter uv picks, and pinning it here would strand the
# project whenever that moves.
write_nvim_pyproject() {
    local dir="$1"

    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} mkdir -p $dir"
        echo -e "${YELLOW}[DRY-RUN]${NC} write virtual project pyproject.toml -> $dir/pyproject.toml"
        return
    fi

    mkdir -p "$dir"
    cat > "$dir/pyproject.toml" << 'EOF'
# Managed by macos-dev-bootstrap/install.sh — a dependency container for
# Neovim's python3 provider (pynvim, molten-nvim, jupytext).
#
# No [build-system] on purpose: that makes this a virtual project, so uv only
# resolves dependencies into .venv instead of trying to build the directory as
# a distribution.
[project]
name = "nvim-python"
version = "0.1.0"
description = "Neovim python3 provider environment"
requires-python = ">=3.11"
dependencies = []
EOF
}

# Python provider + molten-nvim/jupytext dependencies, in their own uv-managed
# venv that nvim points python3_host_prog at.
setup_nvim_python_env() {
    if command -v uv &> /dev/null; then
        local nvim_python_dir="$HOME/.local/share/nvim/python"
        local nvim_pyproject="$nvim_python_dir/pyproject.toml"

        # This directory is only a dependency container for nvim's python3 host
        # (see python3_host_prog in nvim/lua/plugins/molten.lua): nothing in it
        # is ever built or imported as a distribution. `uv init` is the wrong
        # tool for it twice over:
        #
        #   * uv >= 0.12 inits a *packaged* project — [build-system] plus a
        #     src/<name>/ module — so every later `uv add` builds the root, and
        #     any drift between project name and module dir is a hard failure:
        #       × Failed to build `nvim-python @ file:///...nvim/python`
        #       ╰─▶ Expected a Python module at: src/nvim_python/__init__.py
        #     (Exactly what a project inited under the old name hits after the
        #     name is corrected — the module stays at src/python/.)
        #   * The name it defaults to is the directory name, `python`, which uv
        #     refuses to install: a wheel's scripts must not be able to
        #     overwrite the interpreter.
        #
        # A hand-written pyproject with no [build-system] is a virtual project:
        # uv resolves and installs the dependencies into .venv and never builds
        # the root. The directory name stays put — only the metadata is ours.
        if [ ! -f "$nvim_pyproject" ]; then
            info "Creating Neovim Python project at $nvim_python_dir..."
            write_nvim_pyproject "$nvim_python_dir"
        elif grep -q '^\[build-system\]' "$nvim_pyproject"; then
            warn "Project in $nvim_python_dir is a packaged project (uv would build it) — converting to a virtual project"
            write_nvim_pyproject "$nvim_python_dir"
            run rm -rf "$nvim_python_dir/src"
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
}

install_neovim_providers() {
    info "Installing Neovim providers and tools..."

    setup_nvim_python_env

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

# Shared by the full install and targeted (--only) runs: the list of steps that
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
    echo "./install.sh (or just the failed part, e.g. --only <component>) — it is"
    echo "idempotent, finished steps are skipped or refreshed."
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
    echo "  7. Reboot to get the fast key repeat (15ms repeat, 150ms delay)."
    echo "     Every app that is already running keeps the old, slower rate,"
    echo "     so a terminal you never quit will still feel sluggish."
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

    # Targeted run: just the requested components, then report and stop.
    if ((${#ONLY_TARGETS[@]})); then
        ensure_brew_path
        run_only_targets
        if [ "$DRY_RUN" = true ]; then
            echo ""
            echo -e "${YELLOW}This was a dry run. No changes were made.${NC}"
        fi
        if ((${#FAILED_STEPS[@]})); then
            echo ""
            print_failure_summary
            exit 1
        fi
        echo ""
        success "Done: ${ONLY_TARGETS[*]}"
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
    # After backup + configs: config.toml (which binds the plugin actions) and
    # the workspace-manager config symlink are in place first.
    step "herdr plugins"       install_herdr_plugins
    step "git config"          configure_git
    step "default shell"       configure_zsh
    step "non-interactive PATH" configure_noninteractive_path
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
