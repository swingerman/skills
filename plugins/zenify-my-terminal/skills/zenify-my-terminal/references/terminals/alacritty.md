# Alacritty — Setup Reference

Minimal GPU-accelerated terminal. Single TOML config. **No tabs, no splits, no scripting.** Best when the user wants only a terminal and uses tmux for everything else.

## Install

```sh
brew install --cask alacritty font-jetbrains-mono-nerd-font
```

## Config file

`~/.config/alacritty/alacritty.toml` (TOML). Auto-reloads when saved.

## Baseline config

The bundled asset [`assets/terminals/alacritty.toml`](../../assets/terminals/alacritty.toml) sets font, theme, padding, opacity, and a couple of macOS keybindings.

## Tabs and splits

**Alacritty has none.** Use tmux on top:

```sh
brew install tmux
```

- `tmux new -s default` — start a session
- `Ctrl-B c` — new window (tab equivalent)
- `Ctrl-B %` / `Ctrl-B "` — split vertically / horizontally
- `Ctrl-B Arrow` — navigate panes

If the user picks Alacritty, **also walk them through a minimal tmux config** — see [tmux.md](../tmux.md) for a starter `~/.tmux.conf`.

## Project switcher

**Use tmux + fzf**. Add to `~/.zshrc`:

```sh
proj() {
  local d=$(ls ~/projects | fzf)
  [[ -n "$d" ]] && tmux new-session -As "$d" -c "$HOME/projects/$d"
}
```

Then `proj` from any tmux pane jumps you into a session named after the project. `Ctrl-B s` switches between sessions.

## Setup gotchas

### Theme

Alacritty themes ship as separate TOML files. Import via `[general] import = ["~/path/theme.toml"]`. Browse themes at https://github.com/alacritty/alacritty-theme.

### macOS Option key

```toml
[window]
option_as_alt = "Left"
```

### No image protocol

Alacritty doesn't support sixel or kitty image protocols. Image-heavy TUIs (yazi previews) won't show images.
