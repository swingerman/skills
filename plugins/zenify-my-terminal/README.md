# zenify-my-terminal

Set up a fast, calm, focused terminal on macOS.

Walks through the choices, applies the setup, and skips known macOS pitfalls (brew shellenv overhead, deprecated `homebrew/command-not-found` tap, BSD ls vs GNU ls, sub-process PATH, slow synchronous plugin loads).

## What it sets up

- **WezTerm** as the terminal app (with native macOS decorations, JetBrainsMono Nerd Font, Tokyo Night Moon theme, sensible defaults)
- **zinit** as the plugin manager (auto-bootstraps on first run)
- **Starship** or **Oh My Posh** as the prompt (your choice; muted "pure-style" preset)
- The "big three" zsh plugins: syntax-highlighting, autosuggestions, completions
- **fzf** + **fzf-tab** for fuzzy interactive Ctrl-R and Tab menus
- **zoxide** for frecency-based `z` directory jumping
- History config with cross-session sharing, dedup, and Ctrl-P/N prefix search
- Case-insensitive completion + LS_COLORS
- Optional omz snippets: git, sudo, aws, kubectl
- Optional WezTerm extras: project switcher (`Cmd-P`), viddy git-status side pane (`Cmd-G`), lazygit diff viewer (`Cmd-Shift-G`), bottom status bar with workspace + cwd, kill-workspace shortcut

Startup time after optimisations: typically ~2.3s in Apple Terminal (Apple's session restore is ~1.5s of that), and noticeably faster in WezTerm itself.

## Trigger phrases

- "zenify my terminal"
- "set up zsh / shell"
- "make my terminal nice / pretty / awesome"
- "I want to upgrade my terminal experience"
- "switch to wezterm"
- "set up starship / oh-my-posh / zinit"
