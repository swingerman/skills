# cmux — Setup Reference

Native macOS terminal from manaflow-ai, built on **libghostty** (the same render engine that powers Ghostty). Designed around AI coding agents — vertical tabs in a sidebar, per-workspace notification rings when an agent needs attention, an embedded WebKit browser pane, and a socket API for automation. Pure native (not Electron), so startup is fast and memory is low.

Use cmux when the user spends most of their time driving Claude Code / Codex / Aider / Gemini CLI / similar tools and wants the workspace UI tuned for that workflow. Skip it when the user wants Lua scripting (WezTerm) or a minimal terminal (Alacritty).

## Install

```sh
brew tap manaflow-ai/cmux
brew install --cask cmux
```

First launch will trigger Gatekeeper — open from Applications, approve in System Settings → Privacy & Security if blocked.

Repository: https://github.com/manaflow-ai/cmux

## Config file — shared with Ghostty

cmux **automatically reads `~/.config/ghostty/config`** for fonts, themes, colors, and keybindings. There is no separate cmux config file for these. If the user already configured Ghostty, cmux just inherits it; if not, write the same `assets/terminals/ghostty.config` we ship for Ghostty.

Reload: relaunch cmux (Ghostty's `Cmd-Shift-,` reload doesn't apply to cmux).

cmux-specific behavior (vertical tab layout, notification preferences, browser pane, splits) lives in **Settings → ⌘,** inside the app — not in the config file.

## Built-in features (no scripting required)

These are core cmux features. The skill should NOT try to recreate them via shell scripts or zsh functions.

| Feature | What it does |
|---|---|
| **Vertical tabs** | Sidebar lists every open workspace with git branch, PR number/status, working directory, listening ports, and the latest agent notification text |
| **Notification rings** | Glowing indicator when a backgrounded agent needs attention (asks a question, finishes a task) |
| **Split panes** | `Cmd-D` / `Cmd-Shift-D` (inherited from the Ghostty config keybindings) |
| **Embedded browser** | WebKit-based browser pane — open URLs alongside terminal panes without leaving the app |
| **Socket API** | Programmatic control surface for automating tab/workspace creation from scripts |
| **Workspaces** | Each tab is a workspace with isolated state; switch via the sidebar or `Cmd-1..9` |

## What does NOT carry over from WezTerm

cmux has no Lua. The WezTerm power-user extras need different solutions:

| WezTerm feature | cmux equivalent |
|---|---|
| `Cmd-P` project switcher over `~/projects` | Shell function `proj()` (fzf-pick + cd) — bundled in fast-track `.zshrc`. Or use cmux's socket API to script tab creation. |
| `Cmd-G` viddy git-status pane | Manual: `Cmd-D` to split, run `viddy -n 2 git status` in the new pane |
| `Cmd-Shift-G` lazygit pane | Manual: `Cmd-D` to split, run `lazygit` |
| `Cmd-Shift-O` workspace overview | Sidebar always-visible — the overview is built into the UI |
| `Cmd-Shift-Q` kill workspace | Right-click workspace in sidebar → close, or `Cmd-W` from inside |
| Programmable status bar | Per-workspace info already shown in the sidebar (branch / PR / ports / notification text) |

If the user wants the full WezTerm scripting experience, recommend WezTerm instead. cmux's value is the AI-agent-tuned UI, not customizability.

## Recommended workflow with Claude Code

cmux ships with first-class Claude Code support:

1. Open a new workspace (`Cmd-T`)
2. `cd ~/projects/<repo>`
3. Run `claude` (or `claude code`)
4. The sidebar shows the working directory, git branch, and listening ports for that workspace
5. When Claude pauses for input or finishes a task, the workspace ring lights up — switch back via the sidebar

Combine with the bundled themed Claude Code statusline (model · context · rate-limit · branch · effort) for full visibility.

## macOS gotchas

### Sub-process PATH

Like WezTerm, cmux can spawn shells with a minimal PATH (`/usr/bin:/bin:/usr/sbin:/sbin`). If brew tools (`viddy`, `lazygit`, `gh`) don't resolve in cmux panes, this is why. Two fixes:

1. **Preferred**: ensure `~/.zshrc` exports a full PATH including `/usr/local/bin` (or `/opt/homebrew/bin` on Apple Silicon) — interactive shells then have everything.
2. **If non-interactive shells need it too**: cmux Settings → Environment → add `PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin`.

### Font fallback

cmux uses libghostty's font stack, which handles Nerd Font fallback well. Set `font-family = "JetBrainsMono Nerd Font"` in `~/.config/ghostty/config` and glyphs render without extra config.

### Option key

For Esc-prefixed shortcuts in zsh / vim:
```
macos-option-as-alt = left
```

## Alternative cmux-only keybinding file

cmux *additionally* supports `~/.config/ghostty/keybindings` (a separate file, cmux-specific) for overriding shortcuts beyond what fits in the main config. Use this only when the user wants ergonomics that diverge from Ghostty defaults — for most users the bundled config is enough.

## Verify

```sh
ls /Applications/cmux.app                  # cask installed
cat ~/.config/ghostty/config | head -5     # config picked up by cmux
```

Then open cmux manually (Gatekeeper prompt), confirm:
- Sidebar shows on the left with vertical tabs
- Prompt renders with two-line `❯` (Oh My Posh / Starship picked up zsh-side)
- Nerd Font glyphs visible (no boxes)
- `Cmd-D` splits the pane

## Rollback

```sh
brew uninstall --cask cmux
brew untap manaflow-ai/cmux
# ~/.config/ghostty/config is shared with Ghostty — only delete if not using Ghostty too
```
