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

printf "\n%b\n" "${BOLD}Unix Config Sync${RESET}"
printf "%b\n\n" "${DIM}Save this machine's configuration to the repository${RESET}"

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
info "[1/3] Reviewing configuration ${DIM}($branch)${RESET}"
printf "   Each changed file will be shown and confirmed separately.\n\n"

if ! "$SCRIPT_DIR/sync.zsh" save; then
    printf "\n"
    error "Configuration save failed."
    exit 1
fi

printf "\n"
success "Configuration review complete."
printf "\n"

info "[2/3] Staging repository changes"
if ! git add --all; then
    error "Could not stage repository changes."
    exit 1
fi

if git diff --cached --quiet; then
    success "Nothing to save; the repository is already up to date."
    exit 0
fi

success "Changes staged successfully."
printf "\n"

if [[ $# -eq 0 ]]; then
    warning "No commit message provided; changes remain staged."
    printf "   Review with: ${BOLD}git diff --cached${RESET}\n"
    printf "   Commit with: ${BOLD}git commit -m \"your message\"${RESET}\n"
    exit 0
fi

if [[ "$1" == "ts" ]]; then
    commit_message="update at [$(date +'%F %T')]"
else
    commit_message="$*"
fi

info "[3/3] Creating commit"
printf "   Message: %s\n\n" "$commit_message"

if git commit -m "$commit_message"; then
    printf "\n"
    success "Configuration saved and committed."
else
    printf "\n"
    error "Commit failed; the changes are still staged."
    exit 1
fi
