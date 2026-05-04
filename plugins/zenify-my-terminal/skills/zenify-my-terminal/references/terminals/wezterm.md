# WezTerm — Setup Reference

Powerful, scriptable terminal (Lua config). Best when the user wants advanced multi-pane workflows, custom keybindings, or programmable workspaces. Heavier than Ghostty/Alacritty in resource use; far more customizable than iTerm2/Apple Terminal.

## Install

```sh
brew install --cask wezterm font-jetbrains-mono-nerd-font
```

## Config file

`~/.wezterm.lua` (Lua). Auto-reloads when saved.

## Baseline config

The bundled asset [`assets/terminals/wezterm.lua`](../../assets/terminals/wezterm.lua) is a complete starting config including: font, color scheme, sub-process PATH, tab/split/pane keys, bottom status bar, project switcher (tab-based), viddy git-status pane, lazygit pane, kill-workspace shortcut. Each block is labelled — drop the ones the user doesn't want.

## Setup gotchas

### Subprocesses spawned by WezTerm get a minimal PATH

Default is `/usr/bin:/bin:/usr/sbin:/sbin` — no `/usr/local/bin`. So `viddy`, `lazygit`, `oh-my-posh`, etc. won't resolve in spawned panes (they DO work in your shell because the shell's PATH includes brew, but WezTerm's `command = { args = { 'viddy', ... } }` bypasses the shell).

```lua
config.set_environment_variables = {
  PATH = '/usr/local/bin:/usr/local/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:' .. (os.getenv('PATH') or ''),
}
```

### Shift+Enter (and Alt+Enter) submits in Claude Code

By default WezTerm sends the same byte sequence (`\r`) for plain Enter, Shift+Enter, and Alt+Enter, so Claude Code can't distinguish them — every variant submits the prompt. This makes pasting or composing multi-line prompts painful.

**Fix:** enable the Kitty keyboard protocol in `~/.wezterm.lua`:

```lua
config.enable_kitty_keyboard = true
```

WezTerm then sends a disambiguated CSI-u escape sequence for each modified key, which Claude Code recognizes natively. After saving, **open a new WINDOW (not a tab)** for the protocol negotiation to take effect — existing windows keep using the old encoding for their lifetime.

Always-available fallbacks (no config needed): **Ctrl-J** sends a literal LF, and a trailing **`\` + Enter** uses Claude Code's line-continuation parser. Source: [Claude Code Terminal Configuration](https://code.claude.com/docs/en/terminal-config).

This block is included in the bundled `assets/terminals/wezterm.lua`.

### Workspaces are global — multi-window + workspaces don't combine

WezTerm's "active workspace" is a single, process-global value. There's no true per-window workspace mode — `mux.set_active_workspace()` AND `wezterm.action.SwitchToWorkspace { ... }` both mutate the same global. When the active workspace changes, GUI windows attached to other workspaces become hidden.

Practical implication: **don't use workspaces to keep multiple GUI windows independent.** "Open a new window, switch its workspace to project X" looks reasonable but breaks — the new window vanishes (it was attached to the old workspace, which is now inactive) and the original window switches to project X instead.

**For per-project containers use TABS, not workspaces.** Tabs are window-local. Each project = one tab in the current window. Cmd-1 .. Cmd-9 switches tabs. Multi-window then works correctly. The bundled config follows this pattern.

If the user explicitly wants ad-hoc workspaces (e.g. for one-off isolation), they're available — just don't ship a project switcher that uses them.

## Optional power-user features

The bundled `wezterm.lua` includes all of these. Drop the blocks you don't want.

### Pane splits + navigation

- `Cmd-D` / `Cmd-Shift-D` — split horizontally / vertically
- `Cmd-Opt-Arrow` — focus pane in that direction
- `Cmd-Shift-W` — close current pane (Cmd-W still closes the whole tab)

### Bottom status bar (project + cwd)

Active tab title (project name) on the left, cwd on the right. Requires `tab_bar_at_bottom = true`, `use_fancy_tab_bar = false`, `hide_tab_bar_if_only_one_tab = false`.

### Live git-status side pane (viddy)

```sh
brew install viddy
```
- `Cmd-G` — splits a 25%-width right pane running `viddy --interval 2 --differences git status -s`

### Lazygit pane (full diff viewer)

```sh
brew install lazygit
```
- `Cmd-Shift-G` — splits 50% below with lazygit (file list + live diff + stage/commit/branch); `q` quits

### Project switcher (Cmd-P) — tab-based

Fuzzy picker over `~/projects/*`. Each project = one TAB with shell + viddy split. Re-activates an existing tab if the project is already open.

### Workspace navigation (kept for ad-hoc use)

- `Cmd-Shift-]` / `Cmd-Shift-[` — cycle workspaces
- `Cmd-Shift-O` — fuzzy launcher over open workspaces
- `Cmd-Shift-Q` — kill the active workspace (closes every tab in it at once)
