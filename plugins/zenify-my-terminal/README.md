# zenify-my-terminal

Set up a fast, calm, focused terminal on macOS.

Walks through the choices, applies the setup, and skips known macOS pitfalls (brew shellenv overhead, deprecated `homebrew/command-not-found` tap, BSD ls vs GNU ls, sub-process PATH, slow synchronous plugin loads).

## Two modes

- **Guided** — walks through every decision (terminal app, prompt, plugins, optional extras). Best when you want control.
- **Fast track** — one question only ("Which terminal?"), then opinionated optimal defaults. Best when you trust the skill and want a working zenful terminal in a few minutes.

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
