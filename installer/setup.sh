#!/bin/bash
# =============================================================================
# 3b-forge Installer — Global ~/.claude Setup Script
# =============================================================================
#
# Wires ~/.claude (and optionally ~/.claude-work) to a user-provided 3B-style
# knowledge repository. The source repo must follow the 3B layout:
#
#   $FORGE_3B_ROOT/.claude/global-claude-setup/
#     ├── commands/
#     ├── hooks/
#     ├── scripts/
#     ├── templates/CLAUDE.md
#     └── ... (full list in installer/README.md)
#
# Opt-in helper for users who have adopted the 3B methodology. Users without a
# 3B-style repo can copy installer/templates/* into ~/.claude/ manually.
#
# Required env var:
#   FORGE_3B_ROOT                 Path to your 3B repo (no default; fail-fast).
#
# Optional env vars:
#   FORGE_HOME                    Forge repo root. Default: script's parent dir.
#   FORGE_DOTFILES_LINK           Path for dotfiles symlink.
#                                 Default: $HOME/dev/personal/dotfiles.
#                                 Skipped if $FORGE_3B_ROOT/dotfiles absent.
#   FORGE_INSTALL_WORK_PROFILE=1  Enable work profile (~/.claude-work).
#                                 Default: off.
#   FORGE_DRY_RUN=1               Print what would run; make no changes.
#                                 (Or pass --dry-run on the command line.)
#
# Usage:
#   export FORGE_3B_ROOT=/path/to/your/3b
#   ./setup.sh
#
#   # With overrides:
#   FORGE_3B_ROOT=/custom/path FORGE_INSTALL_WORK_PROFILE=1 ./setup.sh --dry-run
#
# Idempotent — safe to run multiple times.
# =============================================================================

set -e

# --- Flag parsing -----------------------------------------------------------
DRY_RUN="${FORGE_DRY_RUN:-0}"
for arg in "$@"; do
	case "$arg" in
	--dry-run) DRY_RUN=1 ;;
	-h | --help)
		sed -n '2,40p' "$0"
		exit 0
		;;
	*)
		echo "Unknown flag: $arg" >&2
		echo "See --help for usage." >&2
		exit 2
		;;
	esac
done

# --- Path resolution --------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_HOME="${FORGE_HOME:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

if [ -z "${FORGE_3B_ROOT:-}" ]; then
	echo "ERROR: FORGE_3B_ROOT must be set before running this installer." >&2
	echo "  Example: export FORGE_3B_ROOT=/path/to/your/3b" >&2
	echo "  See installer/README.md for full setup instructions." >&2
	exit 1
fi

THREE_B="${FORGE_3B_ROOT}"
GLOBAL_SETUP="${THREE_B}/.claude/global-claude-setup"
CLAUDE_DIR="${HOME}/.claude"
CLAUDE_WORK_DIR="${HOME}/.claude-work"

DOTFILES_LINK="${FORGE_DOTFILES_LINK:-${HOME}/dev/personal/dotfiles}"
DOTFILES_TARGET="${THREE_B}/dotfiles"

INSTALL_WORK_PROFILE="${FORGE_INSTALL_WORK_PROFILE:-0}"

# --- Colors -----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Helpers ----------------------------------------------------------------
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
error() {
	echo -e "${RED}[✗]${NC} $1"
	exit 1
}
dry_msg() {
	[ "$DRY_RUN" = "1" ] && echo -e "${YELLOW}[DRY]${NC} $1"
}

# create_symlink: honors DRY_RUN
create_symlink() {
	local source="$1"
	local target="$2"
	local name="$3"

	if [ "$DRY_RUN" = "1" ]; then
		dry_msg "symlink $name: $source -> $target"
		return
	fi

	if [ -L "$target" ]; then
		rm "$target"
	elif [ -e "$target" ]; then
		mv "$target" "${target}.backup.$(date +%Y%m%d%H%M%S)"
		warning "Backed up existing $name"
	fi

	ln -sf "$source" "$target"
	success "$name symlinked"
}

# --- Prerequisites ----------------------------------------------------------
check_prerequisites() {
	[ -d "$THREE_B" ] || error "3B repository not found at $THREE_B (\$FORGE_3B_ROOT)"
	[ -d "$GLOBAL_SETUP" ] || error "Global setup directory not found at $GLOBAL_SETUP"
	success "Prerequisites verified (FORGE_3B_ROOT=$THREE_B)"
	if [ "$DRY_RUN" = "1" ]; then
		warning "DRY RUN — no filesystem changes will be made"
	fi
}

# --- Dotfiles (optional) ----------------------------------------------------
setup_dotfiles_submodule() {
	if [ ! -d "$DOTFILES_TARGET" ]; then
		info "Dotfiles: skipping (${DOTFILES_TARGET} not present in 3B)"
		return
	fi

	info "Checking dotfiles submodule..."

	if [ ! -f "${DOTFILES_TARGET}/bootstrap.sh" ]; then
		info "Initializing dotfiles submodule..."
		if [ "$DRY_RUN" = "1" ]; then
			dry_msg "git -C ${THREE_B} submodule update --init --recursive"
		else
			git -C "${THREE_B}" submodule update --init --recursive
		fi
		success "Dotfiles submodule initialized"
	else
		success "Dotfiles submodule already initialized"
	fi

	if [ -L "$DOTFILES_LINK" ]; then
		success "Dotfiles symlink already exists at $DOTFILES_LINK"
	elif [ -d "$DOTFILES_LINK" ]; then
		warning "$DOTFILES_LINK exists as directory — MANUAL ACTION REQUIRED:"
		warning "  rm -rf $DOTFILES_LINK"
		warning "  ln -s ${DOTFILES_TARGET} ${DOTFILES_LINK}"
	else
		if [ "$DRY_RUN" = "1" ]; then
			dry_msg "mkdir -p $(dirname "$DOTFILES_LINK") && ln -s $DOTFILES_TARGET $DOTFILES_LINK"
		else
			mkdir -p "$(dirname "$DOTFILES_LINK")"
			ln -s "$DOTFILES_TARGET" "$DOTFILES_LINK"
		fi
		success "Created dotfiles symlink at $DOTFILES_LINK"
	fi
}

# --- Setup steps ------------------------------------------------------------
create_directories() {
	info "Creating ~/.claude directories..."
	if [ "$DRY_RUN" = "1" ]; then
		dry_msg "mkdir -p ${CLAUDE_DIR}/plugins/claude-hud"
	else
		mkdir -p "${CLAUDE_DIR}/plugins/claude-hud"
	fi
	success "Directories created"
}

setup_settings() {
	info "Setting up settings.json..."

	if [ -f "${GLOBAL_SETUP}/settings.json" ]; then
		create_symlink "${GLOBAL_SETUP}/settings.json" "${CLAUDE_DIR}/settings.json" "settings.json"
	elif [ ! -f "${CLAUDE_DIR}/settings.json" ]; then
		if [ "$DRY_RUN" = "1" ]; then
			dry_msg "cp ${GLOBAL_SETUP}/templates/settings.example.json ${CLAUDE_DIR}/settings.json"
		else
			cp "${GLOBAL_SETUP}/templates/settings.example.json" "${CLAUDE_DIR}/settings.json"
		fi
		warning "Created settings.json from template (not symlinked)"
		warning "MANUAL ACTION REQUIRED: Edit ~/.claude/settings.json"
		warning "  - Replace YOUR_GITHUB_TOKEN_HERE with your actual GitHub token"
		warning "  - Then move to 3B: mv ~/.claude/settings.json ${GLOBAL_SETUP}/settings.json"
		warning "  - Re-run this script to create symlink"
	else
		success "settings.json already exists (skipped)"
	fi
}

setup_commands() {
	info "Setting up commands symlink..."
	create_symlink "${GLOBAL_SETUP}/commands" "${CLAUDE_DIR}/commands" "commands/"
}

setup_claude_md() {
	info "Setting up CLAUDE.md symlink..."
	create_symlink "${GLOBAL_SETUP}/templates/CLAUDE.md" "${CLAUDE_DIR}/CLAUDE.md" "CLAUDE.md"
}

setup_customizations() {
	info "Setting up CUSTOMIZATIONS.md symlink..."
	create_symlink "${GLOBAL_SETUP}/CUSTOMIZATIONS.md" "${CLAUDE_DIR}/CUSTOMIZATIONS.md" "CUSTOMIZATIONS.md"
}

setup_statusline() {
	info "Setting up statusline-wrapper.sh symlink..."
	create_symlink "${GLOBAL_SETUP}/statusline-wrapper.sh" "${CLAUDE_DIR}/statusline-wrapper.sh" "statusline-wrapper.sh"
}

setup_hud_patches() {
	info "Setting up claude-hud-patches symlink..."
	create_symlink "${GLOBAL_SETUP}/claude-hud-patches" "${CLAUDE_DIR}/claude-hud-patches" "claude-hud-patches/"
}

setup_hud_config() {
	info "Setting up HUD config symlink..."
	create_symlink "${GLOBAL_SETUP}/plugins/claude-hud/config.json" "${CLAUDE_DIR}/plugins/claude-hud/config.json" "plugins/claude-hud/config.json"
}

setup_task_tracker() {
	info "Setting up task-tracker.json symlink..."
	create_symlink "${GLOBAL_SETUP}/task-tracker.json" "${CLAUDE_DIR}/task-tracker.json" "task-tracker.json"
}

setup_scripts() {
	info "Setting up scripts symlink..."
	create_symlink "${GLOBAL_SETUP}/scripts" "${CLAUDE_DIR}/scripts" "scripts/"
}

setup_hooks() {
	info "Setting up hooks symlink..."
	create_symlink "${GLOBAL_SETUP}/hooks" "${CLAUDE_DIR}/hooks" "hooks/"
}

setup_friction_logs() {
	info "Setting up friction-log symlinks..."
	local THREE_B_CLAUDE="${THREE_B}/.claude"
	if [ -f "${THREE_B_CLAUDE}/friction-log.json" ]; then
		create_symlink "${THREE_B_CLAUDE}/friction-log.json" "${CLAUDE_DIR}/friction-log.json" "friction-log.json"
	fi
	if [ -f "${THREE_B_CLAUDE}/friction-log-archive.json" ]; then
		create_symlink "${THREE_B_CLAUDE}/friction-log-archive.json" "${CLAUDE_DIR}/friction-log-archive.json" "friction-log-archive.json"
	fi
}

setup_skills() {
	info "Setting up skills symlink..."
	create_symlink "${THREE_B}/.claude/skills" "${CLAUDE_DIR}/skills" "skills/"
}

setup_rtk() {
	info "Setting up RTK.md symlink..."
	create_symlink "${GLOBAL_SETUP}/RTK.md" "${CLAUDE_DIR}/RTK.md" "RTK.md"
}

# --- Work profile (opt-in) --------------------------------------------------
setup_work_profile() {
	if [ "$INSTALL_WORK_PROFILE" != "1" ]; then
		info "Work profile: skipping (set FORGE_INSTALL_WORK_PROFILE=1 to enable)"
		return
	fi

	info "Setting up work profile (~/.claude-work)..."

	if [ "$DRY_RUN" = "1" ]; then
		dry_msg "mkdir -p ${CLAUDE_WORK_DIR}/plugins/claude-hud"
	else
		mkdir -p "${CLAUDE_WORK_DIR}/plugins/claude-hud"
	fi

	local CHAIN_ITEMS=(
		"CLAUDE.md"
		"CUSTOMIZATIONS.md"
		"commands"
		"hooks"
		"scripts"
		"claude-hud-patches"
		"statusline-wrapper.sh"
		"task-tracker.json"
		"settings.json"
		"RTK.md"
		"friction-log.json"
		"friction-log-archive.json"
	)

	for item in "${CHAIN_ITEMS[@]}"; do
		create_symlink "${CLAUDE_DIR}/${item}" "${CLAUDE_WORK_DIR}/${item}" "work: ${item}"
	done

	create_symlink "${CLAUDE_DIR}/plugins/claude-hud/config.json" \
		"${CLAUDE_WORK_DIR}/plugins/claude-hud/config.json" \
		"work: plugins/claude-hud/config.json"

	create_symlink "${CLAUDE_DIR}/skills" "${CLAUDE_WORK_DIR}/skills" "work: skills/"

	if [ -d "${CLAUDE_DIR}/agents" ]; then
		create_symlink "${CLAUDE_DIR}/agents" "${CLAUDE_WORK_DIR}/agents" "work: agents/"
	fi
	if [ -d "${CLAUDE_DIR}/ide" ]; then
		create_symlink "${CLAUDE_DIR}/ide" "${CLAUDE_WORK_DIR}/ide" "work: ide/"
	fi

	if [ -f "${GLOBAL_SETUP}/settings.local.work.json" ]; then
		create_symlink "${GLOBAL_SETUP}/settings.local.work.json" \
			"${CLAUDE_WORK_DIR}/settings.local.json" \
			"work: settings.local.json (work overrides)"
	else
		warning "settings.local.work.json not found in 3B — work overrides skipped"
	fi

	success "Work profile setup complete"
}

# --- Summary ----------------------------------------------------------------
print_summary() {
	echo ""
	echo "=============================================="
	echo -e "${GREEN}Setup Complete!${NC}"
	echo "=============================================="
	echo ""
	echo "Source repo:  ${THREE_B}"
	echo "Forge root:   ${FORGE_HOME}"
	echo ""
	if [ -d "$DOTFILES_TARGET" ]; then
		echo "Dotfiles:"
		echo "  - ${DOTFILES_LINK} → ${DOTFILES_TARGET}"
		echo ""
	fi
	echo "Personal profile (~/.claude → \$FORGE_3B_ROOT):"
	echo "  - settings.json (shared base)"
	echo "  - commands/ scripts/ hooks/ skills/"
	echo "  - CLAUDE.md CUSTOMIZATIONS.md RTK.md"
	echo "  - statusline-wrapper.sh claude-hud-patches/"
	echo "  - plugins/claude-hud/config.json task-tracker.json"
	echo "  - friction-log.json friction-log-archive.json"
	echo ""
	if [ "$INSTALL_WORK_PROFILE" = "1" ]; then
		echo "Work profile (~/.claude-work → ~/.claude chain):"
		echo "  - All shared config chained through personal"
		echo "  - settings.local.json → work overrides (statusLine, MCP)"
		echo ""
	fi

	echo -e "${YELLOW}Next steps:${NC}"
	echo ""
	echo "  1. Login to Claude Code:"
	echo "     claude"
	echo ""
	echo "  2. Install plugins:"
	echo "     claude plugin install context7"
	echo "     claude plugin install github"
	echo "     claude plugin install claude-hud"
	echo ""
	echo "  3. Apply HUD patches (for multi-account support):"
	echo "     ~/.claude/claude-hud-patches/claude-hud-post-patches.sh"
	echo ""
	if [ "$INSTALL_WORK_PROFILE" = "1" ]; then
		echo "  4. Login to work profile:"
		echo "     CLAUDE_CONFIG_DIR=~/.claude-work claude"
		echo ""
	fi

	echo "Commands available:"
	echo "  /commit, /wrap, /clean-review, /validate-pr-reviews, ..."
	echo ""

	echo "Documentation:"
	echo "  - installer/README.md — setup overview + env vars"
	echo "  - CUSTOMIZATIONS.md — detailed patch documentation"
	echo ""
}

# --- Main -------------------------------------------------------------------
main() {
	echo ""
	echo "=============================================="
	echo "3b-forge Installer — Global ~/.claude Setup"
	echo "=============================================="
	echo ""

	check_prerequisites
	setup_dotfiles_submodule
	create_directories
	setup_settings
	setup_commands
	setup_claude_md
	setup_customizations
	setup_statusline
	setup_hud_patches
	setup_hud_config
	setup_task_tracker
	setup_scripts
	setup_hooks
	setup_friction_logs
	setup_skills
	setup_rtk
	setup_work_profile
	print_summary
}

main "$@"
