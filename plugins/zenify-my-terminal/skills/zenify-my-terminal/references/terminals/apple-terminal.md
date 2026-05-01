# Apple Terminal — Setup Reference

The built-in `Terminal.app`. **Limited but already installed.** Best when the user really doesn't want to install anything else.

## Limitations to call out before the user picks this

- **No true 24-bit color** in older macOS; some themes will look washed out
- **No ligature support** — JetBrainsMono Nerd Font glyphs render but composite ligatures don't
- **No native tabs/splits worth using** — tabs exist but no splits; use tmux
- **Shell session restore** adds ~1.5s to every shell startup (sourced from `/etc/zshrc_Apple_Terminal`)
- **Powerline glyph rendering can be inconsistent** — boxes/cut-off glyphs in some themes

If any of these matter, suggest one of the other terminals.

## Install

It's already installed at `/Applications/Utilities/Terminal.app`. Install the font:

```sh
brew install --cask font-jetbrains-mono-nerd-font
```

## Setup steps (manual)

1. **Terminal → Settings → Profiles**
   - Duplicate the "Basic" profile, rename to "Zenful"
   - Click "Default" to make it the default for new terminals
2. **Profiles → Zenful → Text**
   - Font: `JetBrainsMono Nerd Font`, size 14
   - "Use bold fonts" on
   - "Antialias text" on
3. **Profiles → Zenful → Window**
   - Background opacity: 100% (transparency is buggy with some themes)
4. **Profiles → Zenful → Shell**
   - "When the shell exits": Close if the shell exited cleanly
5. **Import a color scheme** (optional)
   - Download `.terminal` files from https://github.com/lysyi3m/macos-terminal-themes
   - Double-click to import; assign to the Zenful profile

## Tabs and splits

- `Cmd-T` / `Cmd-W` — new tab / close
- `Cmd-1` .. `Cmd-9` — switch tab
- **No splits**. Use tmux on top:
  ```sh
  brew install tmux
  ```
  Then `Ctrl-B %` / `Ctrl-B "` to split.

## Project switcher

Use the same tmux + shell-function approach as Alacritty (see [alacritty.md](alacritty.md#project-switcher)).

## Setup gotchas

### Disabling session restore

To kill the ~1.5s startup overhead from `/etc/zshrc_Apple_Terminal`:

```sh
touch ~/.bash_sessions_disable    # legacy name; still works for zsh in Terminal.app
```

This disables session save/restore for the current user — saves about 1s per shell open.

### Glyph rendering issues

If Powerline arrows / Nerd Font icons look cut off, try:
- Settings → Profiles → Text → "Use bold fonts" toggle
- Settings → Window → "Antialias text" toggle
- Switch to a different Nerd Font (FiraCode, Hack, MesloLGS)
