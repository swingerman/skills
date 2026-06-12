---
description: Create a new git-gtr worktree in the current repo with optional editor/AI launch.
argument-hint: "[branch-name] [--from <ref>] [--from-current] [-e] [-a]"
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

Create a new worktree using `git gtr new` in the **current repo**.

Arguments: `$ARGUMENTS`

## Steps

1. **Verify install.** Run `command -v git-gtr` — if missing, tell the user to run `bash .agents/skills/git-worktree-runner/scripts/install-gtr.sh` and stop.

2. **Verify cwd is a git repo.** Run `git rev-parse --show-toplevel`. Stop if not in a repo.

3. **Resolve the branch name.**
   - If `$1` is provided, use it.
   - Otherwise, ask the user for a branch name. Do not invent one.

4. **Resolve flags from `$ARGUMENTS`.** Pass through `--from <ref>`, `--from-current`, `-e`, `-a` if present.

5. **Pick a base ref (when the user didn't specify one).** If `--from` and `--from-current` are both absent, default to **latest `origin/<default-branch>`** — the most common cause of broken worktrees is branching off a stale local copy.

   Detect the default branch:

   ```bash
   DEFAULT=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
   if [[ -z "$DEFAULT" ]]; then
     # Cricut fallback: DS uses develop, everything else uses main.
     case "$(basename "$(git rev-parse --show-toplevel)")" in
       CricutDesignSpace) DEFAULT=develop ;;
       *) DEFAULT=main ;;
     esac
   fi
   ```

   Then ask one `AskUserQuestion`:

   - *"Branch off latest `origin/$DEFAULT`?"* (Recommended) → fetch and pass `--from origin/$DEFAULT`
   - *"Branch off `HEAD` (whatever's currently checked out)"* → pass `--from-current`
   - *"Branch off a different ref"* → ask for the ref, pass `--from <ref>`

   If the user picks the recommended option, fetch just that one ref first (avoids dragging in unrelated remote refs):

   ```bash
   git fetch origin "$DEFAULT" --quiet
   ```

6. **Warn if no `.gtrconfig`.** If the repo has no `.gtrconfig`, mention that the worktree will be created without `postCreate` hooks (no `npm install` etc.). For `CricutDesignSpace` this is expected — just remind the user to run `npm install` in the new worktree manually. For other Cricut repos, offer to run `bash .agents/skills/git-worktree-runner/scripts/init-gtrconfig.sh` first.

7. **Run** `git gtr new <branch> <flags>` and stream output. Run serially — do **not** background or parallelize concurrent `git gtr new` calls, they can race on `.git/config`.

8. **DS bootstrap (when applicable).** If the repo is `CricutDesignSpace` (basename match), `.gtrconfig` is absent, and the worktree has a `package.json`, the new worktree has no `node_modules` and no `postCreate` hook ran. Ask the user:

   - *"Run `npm install` in the new worktree now? (~3–5 min)"* (Recommended)

   If yes, run it in the background:

   ```bash
   NEW=$(git gtr go <branch>)
   (cd "$NEW" && npm install) &
   echo "npm install running in background (pid $!) — output goes to npm-debug.log on failure"
   ```

   Surface a one-line note that the next likely step is `/gwtr-link-ds` from a canvas worktree, **after** the install completes.

9. **Report** the new worktree path: `git gtr go <branch>` and remind the user how to enter it (`gtr-cd <branch>` or `cd "$(git gtr go <branch>)"`).

## Notes

- Do not use `--force` unless the user explicitly asks for parallel variants of the same branch.
- If the user's intent is to set up canvas → DesignSpace yalc linking after creation, suggest `/gwtr-link-ds` next.
- For `CricutDesignSpace`, the default base branch is `develop`, not `main`. The detection above handles this, but if you hand-write a `--from`, branch off `origin/develop` for DS.
