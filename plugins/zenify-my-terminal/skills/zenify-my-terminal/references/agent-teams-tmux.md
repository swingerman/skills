# Claude Code agent-teams + tmux

Claude Code's **Agent Teams** feature spawns parallel teammate runs as separate panes. The split-pane UI is implemented for **tmux** and **iTerm2 only** — WezTerm, Ghostty, cmux, Kitty, Alacritty have no native integration. ([Source](https://code.claude.com/docs/en/agent-teams))

The cleanest fix for *any* terminal is to run Claude inside tmux. Claude detects `$TMUX` and uses `tmux split-window` automatically. The user keeps their preferred terminal emulator and gains visible parallel teammate panes.

## When this is installed

- **Fast-track**: always installed (tmux + `~/.tmux.conf` + `claude-team` launcher). The `teammateMode` merge into `~/.claude/settings.json` happens **only if `~/.claude/` exists** — same gate as the Claude statusline.
- **Guided mode** (decision #8): opt-in. Suggest it when the user mentions agent teams / parallel subagents / wanting side-by-side teammate output, or when they're on a terminal without native iTerm2-style integration. Don't push it on iTerm2 users — iTerm2 has its own native integration via the `it2` CLI.

## What gets installed and configured

- **tmux** (if not already installed): `brew install tmux`
- **`~/.tmux.conf`**: bundled `assets/tmux.conf` — default `Ctrl-b` prefix, mouse on, true color, vim-style pane nav, intuitive `|` / `-` splits that inherit cwd, minimal status bar that doesn't compete with the user's prompt
- **`claude-team` zsh function**: launches Claude inside a tmux session named `claude` (creates or reattaches as needed)
- **`teammateMode: "tmux"`** in `~/.claude/settings.json`: forces split-pane mode (instead of falling back to in-process)

## Pre-install checks

1. Is tmux already installed? `which tmux && tmux -V` — install if missing.
2. Does the user have an existing `~/.tmux.conf`? If yes, **back it up** before overwriting:
   ```sh
   [[ -f ~/.tmux.conf ]] && cp ~/.tmux.conf ~/.tmux.conf.bak.$(date +%Y%m%d_%H%M%S)
   ```
3. Does `~/.claude/settings.json` exist and is it valid JSON? Use `jq -e . ~/.claude/settings.json` to validate before merging.

## Install

```sh
brew install tmux  # skip if already installed
cp <skill-dir>/assets/tmux.conf ~/.tmux.conf
```

Then add to `~/.zshrc` (in the aliases section):

```zsh
# Claude Code agent-teams launcher: ensure $TMUX is set so split-pane mode activates.
claude-team() {
  if [[ -n "$TMUX" ]]; then
    claude "$@"
  elif tmux has-session -t claude 2>/dev/null; then
    tmux attach-session -t claude
  else
    tmux new-session -s claude "claude $*"
  fi
}
```

Merge `teammateMode` into `~/.claude/settings.json` (use jq, never overwrite the file):

```sh
tmp=$(mktemp)
jq '. + {teammateMode: "tmux"}' ~/.claude/settings.json > "$tmp" && mv "$tmp" ~/.claude/settings.json
```

If the user is running an experimental Claude Code build, also confirm `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set (usually via the `env` block in `~/.claude/settings.json`).

## Verify

```sh
tmux -V                                     # 3.0+ recommended
tmux new-session -d -s _conftest && tmux source-file ~/.tmux.conf ; tmux kill-session -t _conftest
zsh -i -c 'type claude-team'                # should print: claude-team is a shell function
jq '.teammateMode' ~/.claude/settings.json  # should print: "tmux"
```

Then have the user open a new shell and run `claude-team` — they should land in a tmux session called `claude` with Claude Code launched.

## Most important tmux keybindings (with this config)

Prefix is `Ctrl-b`. After hitting prefix, the listed key follows.

### Panes
| Key | Action |
|---|---|
| `prefix \|` | Split current pane horizontally (panes side-by-side) |
| `prefix -` | Split current pane vertically (panes stacked) |
| `prefix h` / `j` / `k` / `l` | Focus pane left / down / up / right |
| `prefix H` / `J` / `K` / `L` | Resize pane (repeatable: hit prefix once, then H/J/K/L freely) |
| `prefix z` | Zoom (toggle fullscreen) the active pane |
| `prefix x` | Kill the active pane (with confirm) |

### Windows (= tmux's tabs)
| Key | Action |
|---|---|
| `prefix c` | New window |
| `prefix n` / `p` | Next / previous window |
| `Alt-←` / `Alt-→` | Cycle windows without prefix |
| `prefix &` | Kill window (with confirm) |
| `prefix 1`..`9` | Jump to window N |

### Sessions
| Key | Action |
|---|---|
| `prefix d` | Detach (leaves tmux running in background) |
| `prefix s` | Session list / picker |
| `tmux ls` (shell) | List sessions |
| `tmux a -t <name>` (shell) | Attach to a named session |

### Copy mode
| Key | Action |
|---|---|
| `prefix [` | Enter copy mode (scrollback) |
| `v` | Begin selection (vi-style) |
| `y` | Copy selection to macOS clipboard |
| `q` | Exit copy mode |

### Misc
| Key | Action |
|---|---|
| `prefix r` | Reload `~/.tmux.conf` |
| Mouse | Click to focus pane, drag border to resize, scroll for scrollback |

## How agent-teams uses these

When `teammateMode` is `tmux` and Claude Code spawns a parallel teammate:
1. It runs `tmux split-window -h` (or similar) in the current window
2. The teammate process attaches to that new pane
3. You can navigate to it with `prefix l` (or click) and watch it work
4. When the teammate finishes, you decide whether to keep the pane or close it (`prefix x`)

## Alternatives

- **iTerm2 + `it2` CLI**: native integration, no tmux needed. Requires switching from your current terminal to iTerm2 and enabling iTerm2's Python API. See [it2](https://github.com/mkusaka/it2).
- **In-process mode**: set `"teammateMode": "in-process"` — all teammates share the current terminal, with no visual separation. Works everywhere, including Apple Terminal.

## Rollback

```sh
# Revert ~/.tmux.conf if backed up
mv ~/.tmux.conf.bak.YYYYMMDD_HHMMSS ~/.tmux.conf

# Remove claude-team function (delete the block from ~/.zshrc)

# Restore previous teammateMode setting
jq 'del(.teammateMode)' ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json
# Or set to "in-process" / "auto" instead of removing
```
