# Claude Code Statusline (opt-in, themed)

Bundled statusline showing **model · context-window usage · rate limits · worktree+branch · effort level**, with **four visual themes** to pick from.

Only relevant if the user uses Claude Code (detect via `[[ -d $HOME/.claude ]]`). Skip silently otherwise.

## Themes

| Theme | Look |
|---|---|
| `pure` (default) | Dim labels, color-coded `[████░░░░] 42%` bar, percentages — like the Pure prompt port |
| `powerline` | Filled-background segments separated by Nerd Font  arrows — like Powerlevel10k Rainbow |
| `rainbow` | Bright fixed colors per segment, ignoring state — playful |
| `minimal` | `model · 42% · main · high effort` — extreme reduction, no bar, no rate limits, no worktree name |

`powerline` looks best in a Nerd Font (the  separator). The skill's font choice (JetBrainsMono Nerd Font) covers it.

Color coding (in `pure` and `minimal`): bar / 5h / 7d go **green ≤50%**, **yellow ≤80%**, **red >80%**.

## Preview themes side-by-side

Run the bundled preview script — renders all four themes with sample data:

```sh
bash <skill-dir>/scripts/preview-statusline-themes.sh
```

Output is the actual rendered statusline for each theme — pick by sight.

## Install

```sh
# 1. Copy the script
cp <skill-dir>/assets/claude/statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh

# 2. Ensure jq is installed (script depends on it)
command -v jq >/dev/null || brew install jq
```

3. **Wire into `~/.claude/settings.json`**, picking the theme by passing it as an argument to the command. Don't overwrite the file — merge with `jq` to preserve existing settings:

```sh
THEME=pure   # or: powerline | rainbow | minimal
tmp=$(mktemp)
if [[ -f ~/.claude/settings.json ]]; then
  jq --arg cmd "sh ~/.claude/statusline-command.sh $THEME" \
     '. + {statusLine: {type: "command", command: $cmd}}' \
     ~/.claude/settings.json > "$tmp" && mv "$tmp" ~/.claude/settings.json
else
  mkdir -p ~/.claude
  printf '{"statusLine": {"type": "command", "command": "sh ~/.claude/statusline-command.sh %s"}}\n' "$THEME" > ~/.claude/settings.json
fi
```

## Switching theme later

Edit `~/.claude/settings.json` and change the `<theme>` argument in the command:

```json
"statusLine": { "type": "command", "command": "sh ~/.claude/statusline-command.sh rainbow" }
```

Then start a new Claude Code session — it picks up the new statusline immediately.

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
