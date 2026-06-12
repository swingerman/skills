#!/usr/bin/env bash
# Install the `gwtr` shell alias plus the upstream `git gtr init <shell>`
# navigation helpers (gtr-cd) into the user's shell profile.
#
# Idempotent: guarded by a `# >>> git-worktree-runner >>>` marker block.
# Re-running replaces the block in place rather than appending duplicates.
#
# Usage:
#   install-alias.sh [--shell zsh|bash] [--profile <path>]
#
# Defaults: detects shell from $SHELL; profile is ~/.zshrc or ~/.bashrc.
set -euo pipefail

SHELL_NAME=""
PROFILE=""

require_value() {
  if [[ $# -lt 2 || -z "${2:-}" ]]; then
    echo "Missing value for $1" >&2
    sed -n '2,12p' "$0"
    exit 2
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --shell) require_value "$@"; SHELL_NAME="$2"; shift 2 ;;
    --profile) require_value "$@"; PROFILE="$2"; shift 2 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

log() { printf '\033[1;34m[gtr-alias]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[gtr-alias]\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31m[gtr-alias]\033[0m %s\n' "$*" >&2; exit 1; }

if ! command -v git-gtr >/dev/null 2>&1; then
  die "git-gtr is not on PATH. Run install-gtr.sh first."
fi

if [[ -z "$SHELL_NAME" ]]; then
  case "${SHELL:-}" in
    */zsh) SHELL_NAME=zsh ;;
    */bash) SHELL_NAME=bash ;;
    *) die "Could not detect shell from \$SHELL=$SHELL. Pass --shell zsh|bash." ;;
  esac
fi

if [[ -z "$PROFILE" ]]; then
  case "$SHELL_NAME" in
    zsh)  PROFILE="$HOME/.zshrc" ;;
    bash) PROFILE="$HOME/.bashrc" ;;
    *) die "Unsupported shell: $SHELL_NAME (zsh and bash only)." ;;
  esac
fi

touch "$PROFILE"

START_MARKER='# >>> git-worktree-runner >>>'
END_MARKER='# <<< git-worktree-runner <<<'

BLOCK="$START_MARKER
# Managed by ops.ai git-worktree-runner skill. Edit between the markers if needed,
# but re-running install-alias.sh will replace the entire block.
alias gwtr='git gtr'
if command -v git-gtr >/dev/null 2>&1; then
  eval \"\$(git gtr init $SHELL_NAME)\"
fi
$END_MARKER"

if grep -qF "$START_MARKER" "$PROFILE"; then
  log "Existing block found in $PROFILE — replacing."
  # Use awk to drop the old block, then append the new one.
  TMP="$(mktemp)"
  awk -v s="$START_MARKER" -v e="$END_MARKER" '
    $0 == s { skip=1; next }
    $0 == e { skip=0; next }
    !skip
  ' "$PROFILE" > "$TMP"
  printf '\n%s\n' "$BLOCK" >> "$TMP"
  mv "$TMP" "$PROFILE"
else
  log "Appending block to $PROFILE"
  printf '\n%s\n' "$BLOCK" >> "$PROFILE"
fi

log "Done. Reload your shell:  source $PROFILE   (or open a new terminal)"
log "Then try:  gwtr ls        # list worktrees"
log "And:       gtr-cd <branch>  # cd into a worktree"
