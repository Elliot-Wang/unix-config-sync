#!/usr/bin/env bash

# Keep the output readable when it is redirected or used in CI.
if [[ -t 1 && "${TERM:-}" != "dumb" ]]; then
    BOLD='\033[1m'
    BLUE='\033[34m'
    GREEN='\033[32m'
    YELLOW='\033[33m'
    RED='\033[31m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    BOLD=''
    BLUE=''
    GREEN=''
    YELLOW=''
    RED=''
    DIM=''
    RESET=''
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

info() {
    printf "%b\n" "${BLUE}::${RESET} $*"
}

success() {
    printf "%b\n" "${GREEN}✓${RESET} $*"
}

warning() {
    printf "%b\n" "${YELLOW}!${RESET} $*"
}

error() {
    printf "%b\n" "${RED}✗${RESET} $*" >&2
}

confirm() {
    local answer

    printf "%b" "${BOLD}$1${RESET} ${DIM}[y/N]${RESET} "
    if ! IFS= read -r answer; then
        printf "\n"
        return 1
    fi

    case "$answer" in
        y|Y|yes|YES|Yes) return 0 ;;
        *)               return 1 ;;
    esac
}

printf "\n%b\n" "${BOLD}Unix Config Sync${RESET}"
printf "%b\n\n" "${DIM}Update local configuration from this repository${RESET}"

if ! command -v git >/dev/null 2>&1; then
    error "Git is not installed or is not available in PATH."
    exit 127
fi

if [[ ! -x "$SCRIPT_DIR/sync.zsh" ]]; then
    error "Cannot execute $SCRIPT_DIR/sync.zsh"
    exit 1
fi

cd "$SCRIPT_DIR" || {
    error "Cannot enter repository: $SCRIPT_DIR"
    exit 1
}

branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || printf 'detached HEAD')
info "[1/2] Syncing repository ${DIM}($branch)${RESET}"

if ! git pull; then
    error "Repository sync failed. No configuration was changed."
    exit 1
fi

success "Repository is up to date."
printf "\n"

info "[2/2] Apply configuration"
printf "   Each changed file will be shown and confirmed separately.\n\n"

if ! confirm "Continue updating this machine?"; then
    warning "Update cancelled. No configuration was applied."
    exit 0
fi

printf "\n"
if "$SCRIPT_DIR/sync.zsh" update; then
    printf "\n"
    success "Configuration update complete."
else
    printf "\n"
    error "Configuration update failed."
    exit 1
fi
