#!/usr/bin/env bash
# Preview Claude Code statusline themes by rendering each one with sample data.
#
# Usage:
#   preview-statusline-themes.sh
#
# Helpful before deciding which theme to set in ~/.claude/settings.json.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATUSLINE="${SCRIPT_DIR}/../assets/claude/statusline-command.sh"

if [[ ! -x "$STATUSLINE" ]]; then
  echo "statusline script not found at $STATUSLINE" >&2
  exit 1
fi

# Synthesize a realistic payload covering all segments
SAMPLE='{
  "model": {"display_name": "claude-opus-4-7"},
  "context_window": {"used_percentage": 42},
  "rate_limits": {
    "five_hour": {"used_percentage": 23},
    "seven_day": {"used_percentage": 12}
  },
  "worktree": {"name": "zenify-my-terminal", "branch": "main"}
}'

THEMES=(pure powerline rainbow minimal)

for t in "${THEMES[@]}"; do
  printf '\n\033[1;36m=== %s ===\033[0m\n' "$t"
  echo "$SAMPLE" | sh "$STATUSLINE" "$t"
  echo
done

echo
echo "To switch theme, edit ~/.claude/settings.json and change the statusLine command:"
echo '  "statusLine": { "type": "command", "command": "sh ~/.claude/statusline-command.sh <theme>" }'
echo
echo "Pick: pure | powerline | rainbow | minimal"
