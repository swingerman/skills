---
description: List all git-gtr worktrees across Cricut repos in the resolved workspace.
argument-hint: "[repo-name]"
allowed-tools:
  - Bash
---

List worktrees across the user's Cricut workspace. The workspace location is **not** assumed to be `~/projects/cricut` — different developers use `~/src/cricut`, `~/work/cricut`, etc.

Arguments: `$ARGUMENTS` (optional — restrict to a single repo by name)

## Steps

1. **Resolve the workspace root** using the snippet from `git-worktree-runner` SKILL.md → "Workspace root resolution":

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
   WS="$(resolve_cricut_workspace)" || { echo "Could not locate Cricut workspace"; exit 1; }
   ```

   If resolution fails, ask the user where their Cricut repos live and suggest `export CRICUT_WORKSPACE=<path>` for next time.

2. **Build the repo list.**

   ```bash
   ls -d "$WS"/*/ 2>/dev/null | xargs -I{} sh -c 'test -d "{}/.git" && echo "{}"'
   ```

   If `$1` is provided, filter to that repo only.

3. **For each repo, list worktrees.** Prefer `git gtr list` for the richer output; fall back to `git worktree list` if `git gtr` is missing.

   ```bash
   for repo in <list>; do
     echo "=== $(basename $repo) ==="
     git -C "$repo" gtr list 2>/dev/null || git -C "$repo" worktree list
   done
   ```

4. **Format the output as a table** with columns: repo · branch · path · short SHA · last commit age. Highlight worktrees with uncommitted changes (`git -C <path> status --short` not empty) using a marker. Classify dirty state into:
   - `[yalc-dirty]` — only `package.json`, `package-lock.json`, and/or `yalc.lock` modified. Routine, not a real issue.
   - `[dirty]` — anything else.

   Detection:

   ```bash
   YALC_RE='^.. (package\.json|package-lock\.json|yalc\.lock)$'
   d=$(git -C "$path" status --short 2>/dev/null)
   if [[ -z "$d" ]]; then marker=""
   elif awk -v re="$YALC_RE" '$0 !~ re { exit 1 } END { exit 0 }' <<<"$d"; then marker="[yalc-dirty]"
   else marker="[dirty]"
   fi
   ```

5. **Yalc link status for DS worktrees.** When the repo basename starts with `CricutDesignSpace` (and isn't `CricutDesignSpaceCanvas*` / `CricutDesignSpaceHome*` / other producer repos), append a per-worktree yalc summary: count of `@cricut/*` packages that have a `yalc.sig` file or are symlinked into `~/.yalc`.

   ```bash
   linked=$(ls -d "$path/node_modules/@cricut/"*/yalc.sig 2>/dev/null | wc -l | tr -d ' ')
   symlinked=$(find "$path/node_modules/@cricut" -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
   total=$((linked + symlinked))
   [[ "$total" -gt 0 ]] && echo "    yalc: $total linked ($linked via add, $symlinked via link)"
   ```

   Use this to spot DS worktrees that *think* they're linked but aren't (because `yalc-add:ds` ran before any producer published — common after a fresh `git gtr new`).

6. **Summarize at the end.** Total worktree count, count of truly-dirty worktrees (yalc-dirty doesn't count), count of yalc-linked DS worktrees, and any repo where `git gtr list` failed (likely missing `.gtrconfig` or stale state — suggest `git gtr clean`).

## Notes

- Don't include the main checkouts unless they're the only entry for a repo.
- Skip directories that aren't git repos (e.g. `*-worktrees` dirs at the workspace root, which are not repos themselves).
- The producer-repo detection (`CricutDesignSpaceCanvas*` / `CricutDesignSpaceHome*` / etc.) is intentionally permissive — if you add a new `@cricut/*` producer repo, just don't run the yalc-link summary on it (it doesn't have consumer `node_modules/@cricut/*` anyway, so the count will be 0 and the line won't print).
