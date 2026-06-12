# `git gtr` command reference

Full subcommand list and notable flags. Run `git gtr <command> --help` for the upstream help text.

## Contents

- [Worktree lifecycle](#worktree-lifecycle) — `new`, `rm`, `mv`, `clean`
- [Navigation](#navigation) — `list`/`ls`, `go`, `run`
- [Editor / AI launchers](#editor--ai-launchers) — `editor`, `ai`, `adapter`
- [File transfer between worktrees](#file-transfer-between-worktrees) — `copy`
- [Configuration](#configuration) — `config`
- [Diagnostics & shell integration](#diagnostics--shell-integration) — `doctor`, `trust`, `init`, `completion`, `version`
- [`.gtrconfig` reference](#gtrconfig-reference)

## Worktree lifecycle

### `git gtr new <branch>`

Create a worktree at `<repo>-worktrees/<branch>/` and (by default) run the `postCreate` hook from `.gtrconfig`.

| Flag | Effect |
|---|---|
| `--from <ref>` | Branch off a specific commit, tag, or branch (default: repo's default branch) |
| `--from-current` | Branch off whatever is currently checked out (useful for parallel variants) |
| `--force` | Allow the same branch to live in multiple worktrees |
| `--name <suffix>` | Append a custom suffix to the worktree folder name |
| `--folder <name>` | Override the worktree folder name entirely |
| `-e`, `--editor` | After creation, open in the configured editor |
| `-a`, `--ai` | After creation, start the configured AI tool |
| `--no-copy` | Skip the `[copy]` step |
| `--no-fetch` | Skip the pre-create `git fetch` |
| `--no-hooks` | Skip the `postCreate` hook |
| `--yes` | Non-interactive mode |
| `-n`, `--dry-run` | Preview without executing |

### `git gtr rm <branch>...`

Remove one or more worktrees.

| Flag | Effect |
|---|---|
| `--delete-branch` | Also delete the local branch |
| `--yes` | Skip confirmation |
| `--force`, `-f` | Remove even with uncommitted changes |

### `git gtr mv <old> <new>`

Rename worktree directory **and** the underlying branch.

### `git gtr clean`

Prune empty directories and stale worktree refs.

| Flag | Effect |
|---|---|
| `--merged` | Remove worktrees whose PRs/MRs have been merged (uses `gh` CLI) |
| `--to <ref>` | Limit cleanup to worktrees branched from `<ref>` |
| `--dry-run` | Preview |
| `--force`, `-f` | Force removal despite local changes |

`--merged` skips worktrees with uncommitted or untracked files — those are surfaced in the dry-run output.

## Navigation

### `git gtr list` / `git gtr ls`

List all worktrees with branch, path, and last-commit info.

### `git gtr go <branch>`

Print the path to a worktree. Use with `cd`:

```bash
cd "$(git gtr go my-feature)"
```

Or use the `gtr-cd` shell function installed by `git gtr init <shell>` for one-shot navigation:

```bash
gtr-cd my-feature
```

### `git gtr run <branch> <cmd...>`

Run a command inside a worktree without changing directories.

```bash
git gtr run my-feature npm test
git gtr run my-feature npm run build -- --watch
```

## Editor / AI launchers

### `git gtr editor <branch>`

Open a worktree in the configured editor. Configure with:

```bash
git gtr config set --global gtr.editor.default vscode
```

### `git gtr ai <branch>`

Launch the configured AI tool in a worktree.

```bash
git gtr config set --global gtr.ai.default claude
```

### `git gtr adapter`

List supported editor and AI adapters.

## File transfer between worktrees

### `git gtr copy <target>...`

Copy uncommitted/untracked files from the current worktree to one or more targets — useful for `.env`, local-only configs, etc. Patterns can be configured under `[copy]` in `.gtrconfig`.

## Configuration

### `git gtr config <get|set|unset> [--global] <key> [value]`

Read/write config. Common keys:

| Key | Example value |
|---|---|
| `gtr.editor.default` | `vscode`, `cursor`, `zed`, `intellij` |
| `gtr.ai.default` | `claude`, `opencode`, `aider`, `copilot` |

Global config lives at `~/.config/git-gtr/config` (XDG default). Repo config lives at `.gtrconfig` in the repo root.

## Diagnostics & shell integration

### `git gtr doctor`

Health check — verifies git/bash versions, PATH, configured adapters, and surfaces actionable issues.

### `git gtr trust`

Approve hook commands flagged as needing user approval (security gate around `postCreate` and friends).

### `git gtr init <shell>`

Print shell integration code (defines `gtr-cd` etc.). Add to your shell profile:

```bash
eval "$(git gtr init zsh)"
eval "$(git gtr init bash)"
```

### `git gtr completion <shell>`

Print shell completion for `bash`, `zsh`, `fish`.

```bash
# zsh
git gtr completion zsh > "${fpath[1]}/_git-gtr"

# bash
git gtr completion bash >> ~/.bashrc
```

### `git gtr version`

Print the installed version.

## `.gtrconfig` reference

```ini
[copy]
# Glob patterns of paths copied into new worktrees during `git gtr new`.
# Useful for local-only files like .env that aren't tracked in git.
.env
.env.local

[hooks]
# Run after `git gtr new` finishes scaffolding the worktree.
postCreate = npm install

[defaults]
editor = vscode
ai = claude
```

Commit `.gtrconfig` so the whole team gets the same hooks. The user's `~/.config/git-gtr/config` overrides these per-user where keys overlap.
