---
description: Preview and run `git gtr clean --merged` to remove worktrees whose PRs have shipped.
argument-hint: "[repo-name]"
allowed-tools:
  - Bash
  - AskUserQuestion
---

Run `git gtr clean --merged` interactively: dry-run first, ask for confirmation, then execute.

Arguments: `$ARGUMENTS` (optional repo name; defaults to the current repo)

## Steps

1. **Resolve target repo.**
   - If `$1` is given, resolve the Cricut workspace root (see SKILL.md → "Workspace root resolution") and `cd` to `<workspace>/$1`. Stop if it's not a git repo.
   - Otherwise use the current repo (`git rev-parse --show-toplevel`).

2. **Verify prerequisites.**
   - `command -v git-gtr` — stop with install hint if missing.
   - `command -v gh && gh auth status` — `clean --merged` calls the GitHub CLI. If missing or unauthenticated, point the user at `references/troubleshooting.md` (covers `brew`, `apt`, `dnf`, `pacman`, plus the upstream Linux install doc) followed by `gh auth login`, and stop.

3. **Run the dry run.**

   ```bash
   git -C <repo> gtr clean --merged --dry-run
   ```

   Capture output. If nothing would be removed, tell the user and stop.

4. **Show the user what would be removed.** Format as a list: branch · worktree path · PR number/state if visible in output. Call out any worktrees that the dry-run flagged as skipped due to dirty state — those won't be removed and the user may want to handle them separately.

5. **Ask for confirmation.** Do not proceed without an explicit yes.

6. **Run for real.**

   ```bash
   git -C <repo> gtr clean --merged --yes
   ```

   `--yes` is required: this command is being run from a non-interactive Claude shell (no TTY), and without it `git gtr clean --merged` prompts `[y/N]` per worktree — every prompt auto-declines and nothing is removed. The user-facing confirmation gate is the `AskUserQuestion` in step 5, not gtr's per-worktree prompt.

   Stream output, then run `git -C <repo> gtr list` and report the new worktree count.

## Notes

- `clean --merged` skips worktrees with uncommitted or untracked files. That's a feature, not a bug.
- For broader cleanup (stale refs, empty dirs) without the `--merged` PR check, use plain `git gtr clean`. Offer that variant only if the user asks.
- Never pass `--force` unless the user specifically asks to remove dirty worktrees.
- The `--yes` flag is only for the gtr per-worktree prompt — it does **not** bypass dirty-state skipping or force-remove anything.
