# Claude Code Statusline (opt-in)

Bundled statusline that shows: **model name · context-window usage bar (green/yellow/red) · 5h and 7d rate-limit percentages · worktree name + branch · effort level**.

Only relevant if the user uses Claude Code (detect via `[[ -d $HOME/.claude ]]`). Skip silently otherwise.

## What it looks like

```
claude-opus-4-7  [████████░░░░░░░░░░░░] 40%  5h: 23%  7d: 12%  worktree: zenify (main)  high effort
```

Color-coded: bar / 5h / 7d each go **green ≤50%**, **yellow ≤80%**, **red >80%**. Model and dim labels (`5h:`, `7d:`, `worktree:`) use ANSI dim. Worktree name is cyan, branch is magenta.

## Install

```sh
# 1. Copy the script
cp <skill-dir>/assets/claude/statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh

# 2. Ensure jq is installed (script depends on it)
command -v jq >/dev/null || brew install jq

# 3. Wire into ~/.claude/settings.json
#    Use the update-config skill OR edit by hand. The block to add:
#    "statusLine": {
#      "type": "command",
#      "command": "sh ~/.claude/statusline-command.sh"
#    }
```

**Preserve existing settings.** Don't overwrite `~/.claude/settings.json` — read it, add/merge the `statusLine` key, write it back. Use `jq` for safety:

```sh
tmp=$(mktemp)
jq '. + {statusLine: {type: "command", command: "sh ~/.claude/statusline-command.sh"}}' \
   ~/.claude/settings.json > "$tmp" && mv "$tmp" ~/.claude/settings.json
```

If `~/.claude/settings.json` doesn't exist yet, create it:

```sh
mkdir -p ~/.claude
echo '{"statusLine": {"type": "command", "command": "sh ~/.claude/statusline-command.sh"}}' > ~/.claude/settings.json
```

## Configuration knobs

The script reads two things from outside its JSON input payload:

- **`effortLevel` from `~/.claude/settings.json`** — set to `"low"`, `"medium"`, or `"high"` to show that label. Omit or leave blank to hide.
- **Rate-limit percentages** — only present in the JSON payload when the user is on a subscription plan that exposes them. The script gracefully omits if absent.

Worktree info is auto-detected by Claude Code when the session is in a git worktree.

## Verify

After installing and wiring up, start a new Claude Code session — the statusline appears at the bottom. If it doesn't render or shows escape codes literally, the terminal probably doesn't support 24-bit color (none of the bundled terminals have this issue, but Apple Terminal can be flaky).

To debug:

```sh
# Synthesize a payload and run the script directly
echo '{"model":{"display_name":"test"},"context_window":{"used_percentage":42}}' | sh ~/.claude/statusline-command.sh
```

Should print a colorized line ending around `42%`.

## Customizing

The script is small and hackable. Common tweaks:

- **Hide a segment**: comment out the corresponding `output="${output}..."` line near the bottom.
- **Change bar width**: change `bar_filled=$(( used_int / 5 ))` and `bar_empty=$(( 20 - bar_filled ))` (currently 20-char bar).
- **Change color thresholds**: edit the `if [ "$used_int" -le 50 ]` blocks.
- **Add new segments**: read additional fields from the input payload via `jq` and append to `output`. The full payload schema: https://docs.claude.com/en/docs/claude-code/statusline.
