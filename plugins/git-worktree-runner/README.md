# git-worktree-runner

Claude Code plugin that helps you install, configure, and use [`git-worktree-runner`](https://github.com/coderabbitai/git-worktree-runner) (`git gtr`) — a git subcommand for parallel-branch development with isolated working directories, `postCreate` hooks, editor/AI launchers, and bulk cleanup of merged worktrees.

## What it does

1. **Walks you through install** on macOS, Linux, and Windows (Git Bash or PowerShell).
2. **Adds a `gwtr` shell alias** plus the upstream `gtr-cd` navigation helper (bash/zsh/fish).
3. **Sets global defaults** for editor and AI tool adapters.
4. **Bootstraps `.gtrconfig`** in repos with sensible `postCreate` hooks (`npm install` etc.).
5. **Wraps day-to-day flows** as six slash commands.
6. **Handles Cricut conventions** for canvas ↔ DesignSpace yalc linking — including the gotchas (`yalc.sig` vs symlink, `dist/util` electron cache, yalc-dirty vs truly-dirty worktrees, default base branches per repo).

## Slash commands

| Command | Effect |
|---|---|
| `/gwtr-new [branch]` | Create a worktree. Fetches and branches off the latest `origin/<default>` by default (DS=develop, others=main). |
| `/gwtr-list [repo]` | List worktrees across the Cricut workspace, with `[dirty]` vs `[yalc-dirty]` markers and per-DS yalc-link counts. |
| `/gwtr-rm [branch]` | Remove a worktree. `cd`s to main checkout first (gtr can't resolve from inside siblings). Treats yalc-only churn as routine. |
| `/gwtr-clean [repo]` | Dry-run `git gtr clean --merged`, ask for confirmation, then execute with `--yes` (needed for non-interactive Claude shells). |
| `/gwtr-doctor` | `git gtr doctor` plus Cricut-specific checks: shell block, gh CLI, `.gtrconfig` per repo, yalc store, DS `dist/util` cache health, yalc-dirty classification. |
| `/gwtr-link-ds [ds-name]` | From a `@cricut/*` producer worktree, link to a chosen DS consumer via `DS_PATH=<chosen> npm run yalc-add:ds` (or `build:yalc:link` for fresh DS worktrees). |

## Triggers

The skill activates on phrases like:

- "install git gtr" / "set up worktree runner"
- "create a worktree" / "make a parallel branch"
- "link canvas to DS" / "yalc add DS"
- "clean up merged worktrees"
- "check my gtr setup" / "is gtr working"

## Cricut workspace

The plugin's slash commands resolve the workspace root in this order:

1. `$CRICUT_WORKSPACE` env var if set.
2. Derived from the current repo's parent (handles `*-worktrees/` siblings).
3. First existing of `~/projects/cricut`, `~/src/cricut`, `~/work/cricut`, `~/code/cricut`, `~/dev/cricut`.

The yalc workflow assumes `CricutDesignSpace` is the consumer and `CricutDesignSpaceCanvas` (or other `@cricut/*` repos with a `yalc-add:ds` / `build:yalc:link` script) is the producer. Full producer↔consumer flow: [`skills/git-worktree-runner/references/yalc-workflow.md`](skills/git-worktree-runner/references/yalc-workflow.md).

## Reference docs

- [Install reference](skills/git-worktree-runner/references/install.md) — manual install paths
- [Command reference](skills/git-worktree-runner/references/commands.md) — every `git gtr` subcommand
- [Troubleshooting](skills/git-worktree-runner/references/troubleshooting.md) — symptom-indexed fixes
- [Yalc workflow](skills/git-worktree-runner/references/yalc-workflow.md) — canvas↔DS producer/consumer end-to-end

## License

MIT
