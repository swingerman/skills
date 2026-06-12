#!/usr/bin/env bash
# Bootstrap a .gtrconfig file in a target repo.
#
# Detects package.json scripts to seed a sensible postCreate hook:
#   - bare repo: no postCreate
#   - has package.json: postCreate = npm install
#   - has package.json + "config" script: extends to npm install &&
#     npm run config -- --env production00a --type SOURCE  (Cricut canvas
#     convention)
#
# Reads the user's global git-gtr defaults to seed [defaults].
#
# Usage:
#   init-gtrconfig.sh [repo-path] [--force]
#
# repo-path defaults to the current directory.
set -euo pipefail

REPO_PATH=""
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    -*) echo "Unknown flag: $1" >&2; exit 2 ;;
    *) REPO_PATH="$1"; shift ;;
  esac
done

REPO_PATH="${REPO_PATH:-$(pwd)}"
REPO_PATH="$(cd "$REPO_PATH" && pwd)"

log() { printf '\033[1;34m[gtrconfig]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[gtrconfig]\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31m[gtrconfig]\033[0m %s\n' "$*" >&2; exit 1; }

if [[ ! -d "$REPO_PATH/.git" ]] && ! git -C "$REPO_PATH" rev-parse --git-dir >/dev/null 2>&1; then
  die "$REPO_PATH is not a git repository."
fi

CONFIG="$REPO_PATH/.gtrconfig"
if [[ -f "$CONFIG" && "$FORCE" -eq 0 ]]; then
  warn ".gtrconfig already exists at $CONFIG. Use --force to overwrite."
  cat "$CONFIG"
  exit 0
fi

# Detect postCreate hook from package.json.
# Use node to look up scripts.config specifically — a top-level `config`
# key in package.json (an unrelated npm field) must not trigger the
# Cricut canvas hook.
POST_CREATE=""
if [[ -f "$REPO_PATH/package.json" ]]; then
  POST_CREATE="npm install"
  has_config_script=$(
    node -e '
      const pkg = require(process.argv[1]);
      process.stdout.write(pkg.scripts && pkg.scripts.config ? "1" : "");
    ' "$REPO_PATH/package.json" 2>/dev/null
  ) || has_config_script=""
  if [[ -n "$has_config_script" ]]; then
    POST_CREATE="$POST_CREATE && npm run config -- --env production00a --type SOURCE"
  fi
fi

# Read global gtr defaults if available.
DEFAULT_EDITOR="vscode"
DEFAULT_AI="claude"
if command -v git-gtr >/dev/null 2>&1; then
  if v=$(git gtr config get --global gtr.editor.default 2>/dev/null); then
    [[ -n "$v" ]] && DEFAULT_EDITOR="$v"
  fi
  if v=$(git gtr config get --global gtr.ai.default 2>/dev/null); then
    [[ -n "$v" ]] && DEFAULT_AI="$v"
  fi
fi

{
  echo "[copy]"
  echo ""
  echo "[hooks]"
  if [[ -n "$POST_CREATE" ]]; then
    echo "postCreate = $POST_CREATE"
  else
    echo "# postCreate = <command to run after creating a worktree>"
  fi
  echo ""
  echo "[defaults]"
  echo "editor = $DEFAULT_EDITOR"
  echo "ai = $DEFAULT_AI"
} > "$CONFIG"

log "Wrote $CONFIG"
log "Review and commit it so the whole team gets the same hooks."
echo "---"
cat "$CONFIG"
