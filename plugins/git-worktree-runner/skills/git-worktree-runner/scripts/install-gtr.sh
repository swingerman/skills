#!/usr/bin/env bash
# Install git-worktree-runner (git gtr).
#
# Order of preference:
#   1. Already installed → exit 0.
#   2. macOS + Homebrew → brew tap coderabbitai/tap && brew install git-gtr.
#   3. Fallback (macOS or Linux) → clone repo to ~/.local/share/git-worktree-runner
#      and symlink bin/git-gtr into ~/.local/bin (no sudo).
#
# Usage:
#   install-gtr.sh [--force]
#
# --force reinstalls even if git-gtr is already on PATH.
set -euo pipefail

FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -h|--help)
      sed -n '2,15p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

log() { printf '\033[1;34m[gtr-install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[gtr-install]\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31m[gtr-install]\033[0m %s\n' "$*" >&2; exit 1; }

if [[ "$FORCE" -eq 0 ]] && command -v git-gtr >/dev/null 2>&1; then
  log "git-gtr already installed at $(command -v git-gtr) ($(git gtr version 2>/dev/null || echo unknown)). Use --force to reinstall."
  exit 0
fi

OS="$(uname -s)"
case "$OS" in
  Darwin) PLATFORM=macos ;;
  Linux)  PLATFORM=linux ;;
  *) die "Unsupported OS: $OS. git-worktree-runner supports macOS and Linux only." ;;
esac

# Prefer Homebrew on macOS.
if [[ "$PLATFORM" == "macos" ]] && command -v brew >/dev/null 2>&1; then
  log "Installing via Homebrew."
  brew tap coderabbitai/tap
  if brew list git-gtr >/dev/null 2>&1; then
    # We only reach here when --force was set (the early exit at the top
    # short-circuits the no-force / already-installed case). `brew install`
    # is a no-op for an installed formula, so use `brew reinstall`.
    log "Already installed — reinstalling (--force)."
    brew reinstall git-gtr
  else
    brew install git-gtr
  fi
  log "Installed: $(git gtr version)"
  exit 0
fi

# Fallback: clone + symlink into ~/.local/bin.
INSTALL_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/git-worktree-runner"
BIN_DIR="$HOME/.local/bin"

log "Cloning git-worktree-runner to $INSTALL_ROOT"
mkdir -p "$(dirname "$INSTALL_ROOT")" "$BIN_DIR"

if [[ -d "$INSTALL_ROOT/.git" ]]; then
  log "Repo already cloned — pulling latest."
  git -C "$INSTALL_ROOT" pull --ff-only
else
  git clone --depth 1 https://github.com/coderabbitai/git-worktree-runner.git "$INSTALL_ROOT"
fi

ln -sf "$INSTALL_ROOT/bin/git-gtr" "$BIN_DIR/git-gtr"
log "Symlinked $BIN_DIR/git-gtr -> $INSTALL_ROOT/bin/git-gtr"

if ! echo ":$PATH:" | grep -q ":$BIN_DIR:"; then
  warn "$BIN_DIR is not on PATH. Add this to your shell profile:"
  warn "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

if command -v git-gtr >/dev/null 2>&1; then
  log "Installed: $(git gtr version)"
else
  warn "Install completed but 'git-gtr' is not yet on PATH for this shell. Open a new terminal or update PATH as shown above."
fi
