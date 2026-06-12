---
name: git-worktree-runner
description: "Helps the user install, configure, and use git-worktree-runner (git gtr) — a git subcommand for parallel-branch development with isolated working directories. Covers installing gtr, setting up a gwtr shell alias, enabling shell navigation helpers, generating completions, running git gtr doctor, bootstrapping a .gtrconfig in a repo, linking a canvas worktree to a DesignSpace consumer worktree via yalc, and using git gtr new / rm / clean / list / run / editor / ai / go / mv / copy. Triggers when the user mentions: install git gtr, set up worktree runner, gwtr alias, create a worktree, link canvas to DS worktree, clean merged worktrees, git gtr config."
---

# Git Worktree Runner (`git gtr`)

[git-worktree-runner](https://github.com/coderabbitai/git-worktree-runner) is a git subcommand that wraps `git worktree` with conventions for parallel-branch development: isolated working directories per branch, `postCreate` hooks (e.g. `npm install`), editor/AI launchers, and bulk cleanup of merged worktrees.

This skill helps users:

1. **Install** `git gtr` on macOS or Linux.
2. **Add a `gwtr` shell alias** (or the upstream shell-navigation helper).
3. **Configure** global defaults (editor, AI tool).
4. **Bootstrap `.gtrconfig`** in a repo with sensible `postCreate` hooks.
5. **Verify** the install with `git gtr doctor`.
6. **Use** the day-to-day commands.

## Prerequisites

- **Git** ≥ 2.17
- **Bash** ≥ 3.2 (4.0+ recommended) — git-gtr itself is a bash script
- Platform support:
  - **macOS / Linux**: native, use the `.sh` installers
  - **Windows**: requires [Git for Windows](https://git-scm.com/download/win) (provides Git Bash). Use the `.ps1` installers; for the navigation helper run the bash installer inside Git Bash. WSL also works as an alternative — install everything inside the WSL distro and treat it as Linux.

## Workflow

Walk the user through these steps in order. Skip any step they've already completed.

### 1. Check current state

Always run first — avoids duplicate installs and surfaces the right next step.

macOS / Linux / Git Bash on Windows:
```bash
command -v git-gtr && git gtr version
```

PowerShell on Windows:
```powershell
Get-Command git-gtr -ErrorAction SilentlyContinue; git gtr version
```

- If found and version prints → skip to step 4 (config).
- If not found → continue to step 2.

### 2. Install `git gtr`

Pick the installer for the user's platform. **Detect the platform from context first** — don't run the wrong script.

**macOS / Linux:**
```bash
bash .agents/skills/git-worktree-runner/scripts/install-gtr.sh
```

The script prefers Homebrew on macOS, falls back to a user-local clone + symlink in `~/.local/bin` (no sudo). Idempotent.

**Windows (PowerShell):**
```powershell
.\.agents\skills\git-worktree-runner\scripts\install-gtr.ps1
```

The PowerShell script verifies Git Bash is available (required — git-gtr is a bash script), clones to `%LOCALAPPDATA%\git-worktree-runner`, and adds `bin\` to the user-level `PATH`. Idempotent. After it runs, **open a new PowerShell window** for the PATH change to take effect.

**Windows (WSL):** Use the macOS / Linux instructions inside the WSL distro.

Manual install reference: [references/install.md](references/install.md).

After install, verify:

```bash
git gtr doctor
```

`doctor` checks Git/Bash versions, PATH, configured editor/AI adapters, and prints any issues.

### 3. Add a shell alias (`gwtr`) and shell helpers

The user asked specifically for a `gwtr` alias. On bash/zsh, the upstream tool also provides `git gtr init <shell>` — a `gtr-cd`-style function so `gtr-cd <branch>` actually `cd`s into the worktree (a plain alias can't do that because aliases run in subshells).

**macOS / Linux / Git Bash on Windows:**
```bash
bash .agents/skills/git-worktree-runner/scripts/install-alias.sh
```

What the script writes (to `~/.zshrc` or `~/.bashrc`, guarded by a `# git-worktree-runner` marker so it's idempotent):

```bash
# >>> git-worktree-runner >>>
alias gwtr='git gtr'
eval "$(git gtr init zsh)"          # or bash, depending on $SHELL
# <<< git-worktree-runner <<<
```

Tell the user to `source ~/.zshrc` (or open a new terminal) afterwards.

**Windows (PowerShell):**
```powershell
.\.agents\skills\git-worktree-runner\scripts\install-alias.ps1
```

This adds a `function gwtr { git gtr @args }` block to the user's `$PROFILE`, marker-guarded for idempotency. PowerShell has no `gtr-cd` equivalent — the upstream `git gtr init` only emits bash/zsh/fish helpers — so navigate with:

```powershell
Set-Location (git gtr go <branch>)
```

Power users who do most of their work in Git Bash on Windows can additionally run `install-alias.sh` inside Git Bash to get the full `gtr-cd` navigation helper there.

**Tab completion** (bash / zsh / fish only):

```bash
git gtr completion zsh > "${fpath[1]}/_git-gtr"   # zsh
git gtr completion bash >> ~/.bashrc              # bash
```

### 4. Set global defaults

Once per machine:

```bash
git gtr config set --global gtr.editor.default vscode   # or cursor, zed, intellij
git gtr config set --global gtr.ai.default claude        # or opencode, aider, copilot
```

Run `git gtr adapter` to see all supported editor / AI adapters.

### 5. Bootstrap a repo's `.gtrconfig`

If the user wants `git gtr new` to auto-run setup commands (e.g. `npm install`) in new worktrees, create a `.gtrconfig` at the repo root:

```bash
bash .agents/skills/git-worktree-runner/scripts/init-gtrconfig.sh [repo-path]
```

The script:

- Defaults to the current working directory if no path given.
- Refuses to overwrite an existing `.gtrconfig` unless `--force` is passed.
- Detects `package.json` and seeds `postCreate = npm install` (extends to the Cricut canvas convention `npm install && npm run config -- --env production00a --type SOURCE` if it sees the `config` script).
- Seeds `[defaults]` from the user's global config.

Example output (matches `CricutDesignSpaceCanvas/.gtrconfig`):

```ini
[copy]

[hooks]
postCreate = npm install

[defaults]
editor = vscode
ai = claude
```

The user should commit `.gtrconfig` so the whole team gets the same hooks.

## Slash commands

The companion plugin (`cricut-desktop-engineering`) ships interactive slash commands that wrap the most common workflows. Prefer them over running raw `git gtr` calls when the user asks for the corresponding action:

| Command | What it does |
|---|---|
| `/gwtr-new [branch]` | Create a worktree in the current repo. Resolves `--from`, `-e`, `-a` from arguments; warns if `.gtrconfig` is missing. |
| `/gwtr-link-ds [ds-name]` | From a canvas-style producer repo, discover available `CricutDesignSpace` worktrees and link via `DS_PATH=<chosen> npm run yalc-add:ds`. |
| `/gwtr-list [repo]` | List worktrees across the resolved Cricut workspace (see [Workspace root resolution](#workspace-root-resolution)), with `[dirty]` vs `[yalc-dirty]` markers and per-DS yalc-link counts. |
| `/gwtr-clean [repo]` | Dry-run `git gtr clean --merged` first, ask for confirmation, then execute with `--yes` (non-interactive shells need it). Verifies `gh` CLI auth. |
| `/gwtr-rm [branch]` | Remove a worktree interactively. `cd`s to the main checkout first (gtr can't resolve worktrees from inside siblings). Treats yalc-only churn as routine. |
| `/gwtr-doctor` | `git gtr doctor` plus Cricut-specific checks (shell block, gh, `.gtrconfig` per repo, yalc store, DS `dist/util` cache health, yalc-dirty vs truly-dirty worktrees). |

When the user asks to "create a worktree", "link to DS", "list worktrees", "clean up merged worktrees", "remove a worktree", or "check my gtr setup", invoke the matching slash command rather than re-deriving the steps.

## Day-to-day commands

Full reference: [references/commands.md](references/commands.md). The most-used:

| Command | What it does |
|---|---|
| `git gtr new <branch>` | Create worktree at `<repo>-worktrees/<branch>/`, run `postCreate` hook |
| `git gtr new <branch> --from <ref>` | Branch off a specific ref instead of the default branch |
| `git gtr new <branch> --from-current` | Branch off whatever you have checked out now |
| `git gtr new <branch> -e` / `-a` | Same, then open editor / start AI tool |
| `git gtr ls` (alias of `list`) | List all worktrees |
| `git gtr go <branch>` | Print the worktree path (use with `cd "$(git gtr go x)"` or the `gtr-cd` helper) |
| `git gtr run <branch> <cmd...>` | Run a command inside a worktree without `cd`ing |
| `git gtr editor <branch>` | Open the worktree in the configured editor |
| `git gtr ai <branch>` | Start the configured AI tool in the worktree |
| `git gtr mv <old> <new>` | Rename worktree **and** branch |
| `git gtr copy <target>...` | Copy uncommitted/untracked files to other worktrees (handy for `.env`) |
| `git gtr rm <branch> [--delete-branch]` | Remove worktree (and optionally the local branch) |
| `git gtr clean` | Prune stale refs and empty directories |
| `git gtr clean --merged [--dry-run]` | Remove worktrees whose PRs are merged (uses `gh` CLI) |
| `git gtr trust` | Approve hook commands flagged as needing user approval |
| `git gtr doctor` | Health check |

## Cricut-specific notes

- **`CricutDesignSpace` works with `git gtr` even though it has no `.gtrconfig`.** `git gtr new` runs fine there — it just skips the `postCreate` hook, so `npm install` must be run manually inside the new DS worktree afterward. **Do not** fall back to plain `git worktree add` for DS; use `git gtr new` (or `/gwtr-new`) consistently across all Cricut repos.
- **Yalc + worktrees:** `yalc push` writes to `~/.yalc`, so `npm run publish:*` works from any worktree. To target a specific consumer worktree, set `DS_PATH`. Full end-to-end producer → consumer flow with verification and gotchas: [references/yalc-workflow.md](references/yalc-workflow.md). For symptoms-based debugging: [references/troubleshooting.md](references/troubleshooting.md).
- **Canvas worktrees:** `CricutDesignSpaceCanvas` ships a `.gtrconfig` with a `postCreate` hook that runs `npm install` and `npm run config -- --env production00a --type SOURCE`. New worktrees are build-ready immediately.
- **Sibling worktree dirs:** Cricut convention puts worktrees at `<RepoName>-worktrees/<branch>/`. `git gtr new` follows this automatically.
- **Default base branches:** `CricutDesignSpace` uses `develop`; everything else (`CricutDesignSpaceCanvas`, `CricutDesignSpaceHome`, etc.) uses `main`. `/gwtr-new` fetches and branches off the latest origin by default — see the command for details.

### Workspace root resolution

Slash commands and the doctor health check need to know where the user keeps their Cricut repos. Different developers use different layouts (`~/projects/cricut`, `~/src/cricut`, `~/work/cricut`, etc.), so resolve in this order:

1. **`$CRICUT_WORKSPACE`** if set and exists — strongest signal, lets users pin it explicitly.
2. **Derive from the current repo.** When invoked inside a Cricut repo, `git rev-parse --show-toplevel`'s parent is the workspace root. If that parent's basename ends in `-worktrees`, go one more level up (so `~/src/cricut/CricutDesignSpaceCanvas-worktrees/feat-x` resolves to `~/src/cricut`).
3. **Fall back to common locations** — first existing of `~/projects/cricut`, `~/src/cricut`, `~/work/cricut`, `~/code/cricut`, `~/dev/cricut`.

Reusable shell snippet:

```bash
resolve_cricut_workspace() {
  if [[ -n "${CRICUT_WORKSPACE:-}" && -d "$CRICUT_WORKSPACE" ]]; then
    echo "$CRICUT_WORKSPACE"; return
  fi
  if root=$(git rev-parse --show-toplevel 2>/dev/null); then
    parent=$(dirname "$root")
    case "$(basename "$parent")" in
      *-worktrees) echo "$(dirname "$parent")"; return ;;
      *) echo "$parent"; return ;;
    esac
  fi
  for c in "$HOME/projects/cricut" "$HOME/src/cricut" "$HOME/work/cricut" "$HOME/code/cricut" "$HOME/dev/cricut"; do
    [[ -d "$c" ]] && { echo "$c"; return; }
  done
  return 1
}
```

If resolution fails, the agent should ask the user where their Cricut repos live and offer to suggest setting `CRICUT_WORKSPACE`.

## Troubleshooting

See [references/troubleshooting.md](references/troubleshooting.md) for:

- `command not found: git-gtr` after install (PATH)
- `gh: command not found` when running `clean --merged`
- Stale worktree refs after manual `rm -rf`
- `postCreate` hook failures
- yalc symlinks pointing to the wrong consumer
