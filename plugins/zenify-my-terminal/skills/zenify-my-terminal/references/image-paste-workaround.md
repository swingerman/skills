# Pasting screenshots into Claude Code (the Cmd+V problem)

Claude Code on macOS supports image paste in theory, but in practice it only works reliably when Claude Code runs **directly in WezTerm/Ghostty/cmux/iTerm2 with no multiplexer in the middle**. The common fast-track stack — Claude Code inside `tmux` (via the `claude-team` launcher) inside WezTerm — breaks Cmd+V image paste because tmux strips/blocks the binary clipboard data on its way through.

This is a known upstream limitation: see Claude Code issues [#834](https://github.com/anthropics/claude-code/issues/834), [#32005](https://github.com/anthropics/claude-code/issues/32005), [#32791](https://github.com/anthropics/claude-code/issues/32791). Claude Code does not yet implement OSC 52 / iTerm2 image / Kitty image protocols natively.

## The workaround: `imgpaste` shell function

Bundled in the fast-track `~/.zshrc` (and listed in [assets/zshrc.zsh](../assets/zshrc.zsh)):

```zsh
imgpaste() {
  local file="/tmp/claude-screenshot-$(date +%s).png"
  if command -v pngpaste >/dev/null 2>&1; then
    pngpaste "$file" 2>/dev/null
  else
    /usr/bin/osascript <<APPLESCRIPT >/dev/null 2>&1
try
  set theData to (the clipboard as «class PNGf»)
  set theFile to (open for access POSIX file "$file" with write permission)
  write theData to theFile
  close access theFile
on error
  try
    close access POSIX file "$file"
  end try
end try
APPLESCRIPT
  fi
  if [[ -s "$file" ]]; then
    echo "$file"
  else
    echo "No image in clipboard." >&2
    rm -f "$file" 2>/dev/null
    return 1
  fi
}
```

Usage:

1. Take a screenshot to clipboard:
   - **Region**: `Cmd-Ctrl-Shift-4` then drag (the `Ctrl` modifier is what sends to clipboard instead of file)
   - **Full screen**: `Cmd-Ctrl-Shift-3`
   - **Or copy any image** (e.g. right-click → Copy Image in a browser)
2. In any shell pane: `imgpaste`
3. The function prints a path like `/tmp/claude-screenshot-1727395823.png`
4. Copy that path and paste it into Claude's prompt — Claude reads file references just fine
5. (Optional) Clean up: `rm /tmp/claude-screenshot-*.png` periodically

## Speed-up: install `pngpaste`

Optional but faster than the AppleScript fallback:

```sh
brew install pngpaste
```

The function auto-detects and prefers it.

## Alternative: skip tmux for image-heavy sessions

If you're doing a lot of screenshot work, run Claude **without** tmux:

```sh
# Instead of: claude-team
claude
```

You lose the agent-teams split-pane support (Claude needs `$TMUX` set for that), but Cmd+V image paste will work directly through WezTerm to Claude Code. Trade-off — pick per session.

## When this stops being needed

Once Claude Code implements OSC 52 / iTerm2 image / Kitty image protocols natively, image paste should work through any multiplexer. Watch issue [#32005](https://github.com/anthropics/claude-code/issues/32005). Until then, `imgpaste` is the reliable workaround.
