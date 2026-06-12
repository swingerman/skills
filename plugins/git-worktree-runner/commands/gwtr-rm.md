---
description: Remove a git-gtr worktree from the current repo with optional branch deletion.
argument-hint: "[branch-name] [--delete-branch]"
allowed-tools:
  - Bash
  - AskUserQuestion
---

Remove a worktree from the current repo using `git gtr rm`.

Arguments: `$ARGUMENTS`

## Steps

1. **Verify install.** Run `command -v git-gtr` — if missing, point the user to:
   - macOS / Linux / Git Bash: `bash .agents/skills/git-worktree-runner/scripts/install-gtr.sh`
   - PowerShell on Windows: `.\.agents\skills\git-worktree-runner\scripts\install-gtr.ps1`

   Then stop. Without this, the next step fails with an unhelpful `git: 'gtr' is not a git command`.

2. **Verify cwd is a git repo and pin to the main checkout.** `git gtr rm`, `editor`, `go`, etc. resolve worktrees relative to the *current* repo. If we're sitting inside a sibling worktree, gtr returns *"Worktree not found for branch: <branch>"* even though the worktree exists. Resolve once and `cd` to the main checkout:

   ```bash
   COMMON=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || { echo "not a git repo"; exit 1; }
   cd "$(dirname "$COMMON")"
   ```

   All subsequent `git gtr` calls in this command run from there.

3. **Resolve the worktree.**
   - If `$1` is given and matches a worktree (`git gtr list`), use it.
   - Otherwise, run `git gtr list`, present the worktrees with `AskUserQuestion`, and let the user pick. Exclude the main checkout from the picker.

4. **Check for dirty state — but classify yalc churn separately.**

   ```bash
   TARGET=$(git gtr go <branch>)
   DIRTY=$(git -C "$TARGET" status --short)
   ```

   If `DIRTY` is empty, skip ahead to step 5.

   Otherwise, partition the dirty files:

   ```bash
   YALC_PATHS='^.. (package\.json|package-lock\.json|yalc\.lock)$'
   yalc_only=$(awk -v re="$YALC_PATHS" '$0 !~ re { print; exit 1 } END { exit 0 }' <<<"$DIRTY")
   ```

   (`yalc_only` exits 0 iff every dirty line matches the yalc-routine paths.)

   - **All dirty paths are yalc-routine** (`package.json`, `package-lock.json`, `yalc.lock`): show the file list and ask "looks like routine yalc state — safe to force-remove?" Default to yes. If yes, plan to pass `--force`.
   - **Anything else is dirty:** list the dirty files in full and ask explicitly whether to:
     - Stop and let them commit/stash first
     - Force-remove with `--force` (data-loss warning)

5. **Decide branch deletion.**
   - If `--delete-branch` is in `$ARGUMENTS`, pass it through.
   - Otherwise, ask the user "delete the local branch too?" with `AskUserQuestion`. Default to no.

6. **Run.**

   ```bash
   git gtr rm <branch> [--delete-branch] [--force]
   ```

   Stream output and confirm the worktree is gone (`git gtr list`).

## Notes

- Don't pass `--yes` — keep gtr's own confirmation as a second guard.
- Never pass `--force` without the user agreeing in step 4.
- For bulk removal, run the command multiple times rather than chaining branches in one call — easier to reason about per-worktree dirty state.
