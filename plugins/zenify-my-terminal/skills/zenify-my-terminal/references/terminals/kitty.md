# Kitty — Setup Reference

Mature, GPU-accelerated terminal with native tabs/splits, Python "kittens" (extensions), and a sensible `kitty.conf` format. Sits between Ghostty (simpler) and WezTerm (more programmable). Best for users wanting power features without learning Lua.

## Install

```sh
brew install --cask kitty font-jetbrains-mono-nerd-font
```

## Config file

`~/.config/kitty/kitty.conf` (custom format). Reload with `Ctrl-Shift-F5` (default), or set `allow_remote_control yes` and run `kitty @ load-config`.

## Baseline config

The bundled asset [`assets/terminals/kitty.conf`](../../assets/terminals/kitty.conf) sets font, theme, padding, and remaps tabs/splits to Cmd-prefixed shortcuts (default Kitty uses Ctrl-Shift).

## Tabs and splits (Kitty calls splits "windows")

After loading the bundled config:

- `Cmd-T` / `Cmd-W` — new tab / close tab
- `Cmd-1` .. `Cmd-9` — switch to tab N
- `Cmd-Enter` — new split (Kitty layout-dependent)
- `Cmd-]` / `Cmd-[` — focus next/previous split
- `Cmd-D` / `Cmd-Shift-D` — split right / split down (custom binding in baseline)

Kitty has **layouts** (tall, fat, grid, splits, stack) — switch with `Ctrl-Shift-L`.

## Project switcher

Kitty supports a built-in "kitten" — a Python script you can bind to a key. The bundled config includes a `cmd+p` binding that runs `kitten ssh`-style fuzzy launcher over `~/projects`. Or use the same shell-function + tmux approach as Alacritty if you prefer not to write Python.

For a minimal launch-fzf-and-cd kitten see https://sw.kovidgoyal.net/kitty/kittens_intro/.

## Setup gotchas

### macOS Option key

```
macos_option_as_alt yes
```

### Theme

Run `kitten themes` to browse and pick interactively (writes to `kitty.conf`), or set `include themes/<name>.conf`.

### Cmd-prefix vs Ctrl-Shift-prefix

Kitty defaults to Ctrl-Shift- for everything. The bundled config remaps to Cmd- which is more macOS-natural.
