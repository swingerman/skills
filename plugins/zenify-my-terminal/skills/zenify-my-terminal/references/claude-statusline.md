# Claude Code Statusline (opt-in, themed)

Bundled statusline showing **model · context-window usage · rate limits · worktree+branch · effort level**, with **seven visual themes** to pick from.

Only relevant if the user uses Claude Code (detect via `[[ -d $HOME/.claude ]]`). Skip silently otherwise.

## Themes

| Theme | Look | Inherits terminal palette? |
|---|---|---|
| `pure` (default) | Dim labels, color-coded `[████░░░░] 42%` bar, percentages — like the Pure prompt port | ✅ |
| `powerline` | Filled-background segments separated by Nerd Font  arrows — like Powerlevel10k Rainbow | ✅ |
| `rainbow` | Bright **fixed** colors per segment via 256-color palette indices — playful, but doesn't follow your terminal theme | ❌ |
| `terminal` | Compact multi-color layout per segment using ANSI base colors — inherits your terminal's active palette (Tokyo Night, Dracula, Solarized, etc.). Strips parenthetical model info, uses a 12-char bar and a single-letter effort glyph (`⚡h`) so the line stays under ~75 chars and survives Claude Code's 80-col truncation. | ✅ |
| `panels` | **Most graphical (theme-neutral)**: filled backgrounds per segment (each its own dark muted shade), Nerd Font  /  rounded caps on the first and last segment, Nerd Font  arrow separators between segments, Nerd Font icons per segment (clock for 5h, calendar for 7d, folder for worktree, branch glyph, ⚡ for effort). Uses 256-color dark bgs (~10–20% brightness) with bright accent foreground text — readable and discrete, not saturated. Compact (10-char bar, single-letter effort, stripped model name) — fits 80 cols. | ⚠️ partially (foreground inherits palette only via the bright accent slots; backgrounds are 256-color dark shades for contrast control) |
| `catppuccin-mocha` | **Catppuccin Mocha–branded**: same chrome as `panels` (rounded caps,  arrows, icons), but the alternating Surface0/Surface1 backgrounds and per-segment accent foregrounds (Sapphire context, Yellow 5h, Green 7d, Sky worktree, Mauve branch, Peach effort, Text model) come from the official Catppuccin palette via 24-bit color codes. Coordinates visually with the OMP `catppuccin_mocha` prompt. | ❌ (uses fixed Catppuccin RGB values regardless of terminal palette — pair with a Catppuccin terminal scheme for the best look) |
| `minimal` | `model · 42% · main · high effort` — extreme reduction, no bar, no rate limits, no worktree name | ✅ |

**Theme-aware vs fixed.** Themes that use ANSI base color codes (`\033[31m`, `\033[91m`, etc.) render through the terminal's active palette — change WezTerm/Ghostty/cmux from Tokyo Night Moon to Dracula and the statusline colors swap automatically. `rainbow` and `panels` use 256-color indices for some or all of their colors: `rainbow` for everything, `panels` only for the dark backgrounds (it picks specific muted shades for contrast control). If you want the per-segment colorful look but want it to fully inherit your terminal theme, use `terminal`. If you want the most graphical chrome (rounded caps, filled backgrounds, icons), use `panels`.

**Picking by visual style:**
- *I want plain text in colors that match my terminal*: `pure`, `terminal`, `minimal`
- *I want filled backgrounds per segment*: `panels` (compact, with icons) or `powerline` (full-width, no leading icons)
- *I want bright fixed colors regardless of terminal theme*: `rainbow`

`powerline` and `panels` look best in a Nerd Font (the  arrow separator and the per-segment icons). The skill's font choice (JetBrainsMono Nerd Font) covers it.

Color coding (in `pure` and `minimal`): bar / 5h / 7d go **green ≤50%**, **yellow ≤80%**, **red >80%**.

## Preview themes side-by-side

Run the bundled preview script — renders all seven themes with sample data:

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
THEME=pure   # or: powerline | rainbow | terminal | panels | catppuccin-mocha | minimal
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
