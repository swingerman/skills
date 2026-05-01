# iTerm2 — Setup Reference

Established macOS terminal. Mature, full-featured, **GUI-configured** (preferences pane). Best when the user prefers clicking through preferences over editing config files.

## Install

```sh
brew install --cask iterm2 font-jetbrains-mono-nerd-font
```

## Config

iTerm2 stores preferences in `~/Library/Preferences/com.googlecode.iterm2.plist`. **No text-file config** in the way the others have. Customization is done in **iTerm2 → Settings**.

## Setup steps (manual — walk the user through these)

1. **Settings → Profiles → Default → Text**
   - Font: `JetBrainsMono Nerd Font`, size 14
   - "Use a different font for non-ASCII text" off (Nerd Font handles fallback)
2. **Settings → Profiles → Default → Colors**
   - Color Presets → Import → `~/Downloads/<theme>.itermcolors`
   - Tokyo Night Moon, Tokyo Night Storm, etc. available at https://iterm2colorschemes.com
3. **Settings → Profiles → Default → Keys → General**
   - Left Option Key: `Esc+`
   - Right Option Key: `Esc+`
4. **Settings → Profiles → Default → Window**
   - Transparency: 0–10% if desired
   - Padding: 10 pt each side via "Style of bezel"
5. **Settings → Appearance → General**
   - Theme: Minimal (least visual chrome)
6. **Settings → Profiles → Default → Working Directory**
   - "Reuse previous session's directory" on (so new tabs/splits start in the right place)

## Tabs and splits

Native:

- `Cmd-T` / `Cmd-W` — new tab / close tab
- `Cmd-1` .. `Cmd-9` — switch tab
- `Cmd-D` / `Cmd-Shift-D` — split vertical / horizontal
- `Cmd-Opt-Arrow` — focus split

## Project switcher

iTerm2 has **profile dynamic configuration** that can be scripted, but it's heavier than the others. Pragmatic approaches:

1. **iTerm2 "Open Quickly"** (`Cmd-Shift-O`) — searches sessions/tabs/profiles. Create one profile per project (with a starting `cd`) and open them by name.
2. **Use tmux + the shell function approach** (see [alacritty.md](alacritty.md#project-switcher)).

## Setup gotchas

### Shell integration

iTerm2 ships a shell-integration script (`Settings → Profiles → Advanced → Install Shell Integration`). It enables marks, alerts, and per-prompt directory tracking. **Don't enable it if you're using Starship/Oh My Posh** — they conflict.

### Status bar

iTerm2 has a built-in status bar (`Settings → Profiles → Session → Status Bar Enabled`). Drag-drop components. Heavier than the WezTerm/Kitty equivalents but no config required.
