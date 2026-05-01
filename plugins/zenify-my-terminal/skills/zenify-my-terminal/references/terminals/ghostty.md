# Ghostty — Setup Reference

Mitchell Hashimoto's terminal. Native macOS, very fast, simple key=value config. Newer than the others; Wayland/macOS only. Best when the user wants speed + sane defaults without writing Lua.

## Install

```sh
brew install --cask ghostty font-jetbrains-mono-nerd-font
```

## Config file

`~/.config/ghostty/config` (custom key=value format). Reload with `Cmd-Shift-,`.

## Baseline config

The bundled asset [`assets/terminals/ghostty.config`](../../assets/terminals/ghostty.config) sets font, theme, padding, and a few quality-of-life keybindings.

## Tabs and splits

Ghostty has **native tabs and splits** without scripting:

- `Cmd-T` / `Cmd-W` — new tab / close tab
- `Cmd-1` .. `Cmd-9` — switch to tab N
- `Cmd-D` / `Cmd-Shift-D` — split right / split down
- `Cmd-Opt-Arrow` — focus split in direction
- `Cmd-Shift-Enter` — toggle split zoom (full-screen current pane)

## Project switcher

**Ghostty has no scripting/Lua.** Project-switcher-style fuzzy pickers aren't natively achievable.

Workarounds:
1. **Use tmux on top** — `tmux` sessions per project, fuzzy-switch with a shell function (`fzf | tmux switch-client`). Works in any terminal.
2. **Shell function + Cmd-T** — a `proj` zsh function: `proj() { local d=$(ls ~/projects | fzf); cd ~/projects/$d; }`. User then opens a new tab manually.
3. **Use a different terminal** — WezTerm or Kitty if a built-in project switcher is important.

## Setup gotchas

### Theme list

Browse with `ghostty +list-themes`. Pick by name in `theme = ...`.

### Font fallback

Ghostty handles Nerd Font fallback well — set `font-family = "JetBrainsMono Nerd Font"` and you get glyphs without extra config.

### macOS Option key

Default behavior is to compose Unicode (left option). For Esc-prefixed shortcuts in zsh/vim, set:
```
macos-option-as-alt = left
```
