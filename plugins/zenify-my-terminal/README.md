# zenify-my-terminal

Set up a fast, calm, focused terminal on macOS.

Walks through the choices, applies the setup, and skips known macOS pitfalls (brew shellenv overhead, deprecated `homebrew/command-not-found` tap, BSD ls vs GNU ls, sub-process PATH, slow synchronous plugin loads).

## Two modes

- **Guided** — walks through every decision (terminal app, prompt, plugins, optional extras). Best when you want control or have an unusual existing setup.
- **Fast track** — zero questions, applies the opinionated stack the skill was built around:
  - **WezTerm** as the terminal (JetBrainsMono Nerd Font, **Catppuccin Macchiato** color scheme)
  - **Oh My Posh** with the `catppuccin.omp.json` theme — rounded-pill segments (Blue user/host, Pink path, Lavender git branch) coordinated with the Macchiato terminal palette
  - **zinit** with turbo-mode plugins: zsh-syntax-highlighting, zsh-autosuggestions, zsh-completions, fzf-tab
  - **fzf**, **zoxide**, **viddy**, **lazygit**, **tmux**, **pngpaste** installed
  - omz snippets: `git`, `sudo`, `aws`, `kubectl`
  - WezTerm bottom status bar (project | git branch | worktree | cwd), pane splits (`Cmd-D` / `Cmd-Shift-D`), pane focus (`Cmd-Opt-Arrow`)
  - Project switcher (`Cmd-P` over `~/projects/*`) — tab-based, with auto-split shell + viddy git-status pane
  - Lazygit pane (`Cmd-Shift-G`)
  - Workspace nav (`Cmd-Shift-]/[/O/Q`)
  - **tmux** + `~/.tmux.conf` + `claude-team` zsh launcher so Claude Code's agent-teams feature can spawn parallel teammates as split panes (works in any terminal once you're inside tmux)
  - **`imgpaste`** zsh function: workaround for Cmd+V image paste not reaching Claude Code through tmux+WezTerm — saves clipboard image to `/tmp/claude-screenshot-<ts>.png` and prints the path
  - WezTerm `enable_kitty_keyboard = true` so Shift+Enter inserts a newline in Claude Code's prompt instead of submitting

  - **Bonus**: if `~/.claude/` exists, also installs a custom Claude Code statusline themed `catppuccin-macchiato` (Macchiato Surface backgrounds with Sapphire/Yellow/Green/Sky/Mauve/Peach accents, rounded caps, icons, fits 80 cols) and merges `teammateMode: "tmux"` into `~/.claude/settings.json`

  Best when you trust the defaults and want a working zenful terminal in a few minutes.

## Terminal-neutral

The skill supports seven terminals, each with its own per-terminal reference and (where applicable) a baseline config asset:

| Terminal | Strength | Tabs/splits |
|---|---|---|
| WezTerm | Most powerful (Lua scripting, custom workspaces) | Native + scriptable |
| Ghostty | Fast, native macOS, simple config | Native |
| cmux | Native macOS app on libghostty, AI-coding-agent UI (vertical tabs sidebar with branch/PR/ports/notification rings, embedded WebKit browser). Inherits Ghostty's config. | Native |
| Kitty | Mature middle ground, Python "kittens" | Native |
| Alacritty | Minimal, GPU, single TOML file | None — pair with tmux |
| iTerm2 | Established, GUI-configured | Native |
| Apple Terminal | Built-in, no install needed | Tabs only — pair with tmux for splits |

The skill picks the right reference based on your choice and bundles a starter config for the scriptable ones (cmux uses the same config asset as Ghostty).

## What the skill sets up

- **The chosen terminal**, configured with JetBrainsMono Nerd Font, Tokyo Night theme, sensible padding/decorations, and (for terminals that support it) tab/split keybindings, status bar, project switcher
- **zinit** plugin manager (auto-bootstraps on first run)
- **Starship** or **Oh My Posh** prompt (your choice; muted "pure-style" preset)
- The "big three" zsh plugins: syntax-highlighting, autosuggestions, completions
- **fzf** + **fzf-tab** for fuzzy interactive Ctrl-R and Tab menus
- **zoxide** for frecency-based `z` directory jumping
- History config with cross-session sharing, dedup, and Ctrl-P/N prefix search
- Case-insensitive completion + LS_COLORS
- Optional omz snippets: git, sudo, aws, kubectl
- Optional power-user extras (terminal-dependent): project switcher (`Cmd-P` over `~/projects/*`), viddy git-status pane, lazygit diff viewer, programmable status bar, kill-workspace shortcut
- Optional **tmux for Claude Code agent teams** (any terminal): `~/.tmux.conf` + `claude-team` launcher + `teammateMode: "tmux"` so Claude's parallel teammates spawn as split panes. Necessary on WezTerm/Ghostty/cmux/Kitty/Alacritty — Claude Code's split-pane mode is implemented for tmux and iTerm2 only.

Ends every run with a cheat-sheet of what you have and the most important keyboard shortcuts.

## Trigger phrases

- "zenify my terminal"
- "set up zsh / shell"
- "make my terminal nice / pretty / awesome"
- "I want to upgrade my terminal experience"
- "fast track my terminal setup" / "just set me up" / "use the defaults"
- "set up starship / oh-my-posh / zinit"
- "switch to wezterm / ghostty / cmux / kitty / alacritty"
