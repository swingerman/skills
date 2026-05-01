# zenify-my-terminal

Set up a fast, calm, focused terminal on macOS.

Walks through the choices, applies the setup, and skips known macOS pitfalls (brew shellenv overhead, deprecated `homebrew/command-not-found` tap, BSD ls vs GNU ls, sub-process PATH, slow synchronous plugin loads).

## Two modes

- **Guided** — walks through every decision (terminal app, prompt, plugins, optional extras). Best when you want control or have an unusual existing setup.
- **Fast track** — zero questions, applies the opinionated stack the skill was built around:
  - **WezTerm** as the terminal (JetBrainsMono Nerd Font, Tokyo Night Moon)
  - **Oh My Posh** with the `pure` theme as the prompt
  - **zinit** with turbo-mode plugins: zsh-syntax-highlighting, zsh-autosuggestions, zsh-completions, fzf-tab
  - **fzf**, **zoxide**, **viddy**, **lazygit** installed
  - omz snippets: `git`, `sudo`, `aws`, `kubectl`
  - WezTerm bottom status bar (project + cwd), pane splits (`Cmd-D` / `Cmd-Shift-D`), pane focus (`Cmd-Opt-Arrow`)
  - Project switcher (`Cmd-P` over `~/projects/*`) — tab-based, with auto-split shell + viddy git-status pane
  - Lazygit pane (`Cmd-Shift-G`)
  - Workspace nav (`Cmd-Shift-]/[/O/Q`)

  - **Bonus**: if `~/.claude/` exists, also installs a custom Claude Code statusline (model name, color-coded context-window bar, 5h/7d rate-limit percentages, worktree+branch, effort level)

  Best when you trust the defaults and want a working zenful terminal in a few minutes.

## Terminal-neutral

The skill supports six terminals, each with its own per-terminal reference and (where applicable) a baseline config asset:

| Terminal | Strength | Tabs/splits |
|---|---|---|
| WezTerm | Most powerful (Lua scripting, custom workspaces) | Native + scriptable |
| Ghostty | Fast, native macOS, simple config | Native |
| Kitty | Mature middle ground, Python "kittens" | Native |
| Alacritty | Minimal, GPU, single TOML file | None — pair with tmux |
| iTerm2 | Established, GUI-configured | Native |
| Apple Terminal | Built-in, no install needed | Tabs only — pair with tmux for splits |

The skill picks the right reference based on your choice and bundles a starter config for the four scriptable ones.

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

Ends every run with a cheat-sheet of what you have and the most important keyboard shortcuts.

## Trigger phrases

- "zenify my terminal"
- "set up zsh / shell"
- "make my terminal nice / pretty / awesome"
- "I want to upgrade my terminal experience"
- "fast track my terminal setup" / "just set me up" / "use the defaults"
- "set up starship / oh-my-posh / zinit"
- "switch to wezterm / ghostty / kitty / alacritty"
