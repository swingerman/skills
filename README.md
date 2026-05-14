# Claude Code utilities

A personal marketplace of utility-only [Claude Code](https://docs.claude.com/en/docs/claude-code) plugins — small, single-purpose tools that don't belong to a larger methodology.

> ℹ️ **Methodology plugins moved.** The `crap-analyzer` plugin has migrated to [`swingerman/atdd`](https://github.com/swingerman/atdd) (renamed to `swingerman/disciplined-agentic-engineering`) where it joins the rest of the **Disciplined Agentic Engineering (DAE)** methodology kit. This marketplace stays focused on standalone utilities.

## Install the marketplace

```bash
/plugin marketplace add swingerman/skills
```

Then install individual plugins:

```bash
/plugin install zenify-my-terminal@swingerman-skills
```

## Plugins

### [zenify-my-terminal](plugins/zenify-my-terminal)

Set up a fast, calm, focused terminal on macOS. Two modes:

- **Guided** — walks through every choice between WezTerm/Ghostty/cmux/Alacritty/Kitty/iTerm2/Apple Terminal, Starship/Oh My Posh with live theme preview, plugins, optional extras
- **Fast-track** — zero questions; fully coordinated Catppuccin Macchiato stack (WezTerm + JetBrainsMono Nerd Font + Catppuccin Macchiato + OMP catppuccin.omp.json + zinit turbo + tmux + git/sudo/aws/kubectl + project switcher + viddy + lazygit + git-aware status bar)

When `~/.claude/` is detected, also installs a custom catppuccin-macchiato statusline (model + context bar + rate limits + worktree + effort) and merges `teammateMode=tmux` into settings.json.

Trigger by running `/zenify-my-terminal` or saying *"zen-ify my terminal"*.

## Where else to look

- **Methodology kit (DAE) + ATDD + crap-analyzer**: [`swingerman/atdd`](https://github.com/swingerman/atdd) (rename pending → `swingerman/disciplined-agentic-engineering`)

## Repo layout

```
.
├── .claude-plugin/
│   └── marketplace.json            # marketplace manifest
└── plugins/
    └── zenify-my-terminal/
        ├── .claude-plugin/
        │   └── plugin.json
        └── skills/
            └── zenify-my-terminal/
```

## License

MIT — see [LICENSE](LICENSE).
