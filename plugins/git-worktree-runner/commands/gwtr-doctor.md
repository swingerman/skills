---
description: Run `git gtr doctor` plus Cricut-specific health checks for the worktree setup.
allowed-tools:
  - Bash
---

Run a health check across the gtr install, shell integration, and Cricut workspace conventions.

## Steps

1. **gtr binary check.**
   - `command -v git-gtr && git gtr version`
   - If missing → install hint and stop.

2. **gtr's own doctor.**

   ```bash
   git gtr doctor
   ```

   Surface any failures verbatim.

3. **Shell integration.**
   - Look for the `# >>> git-worktree-runner >>>` block in `~/.zshrc` and `~/.bashrc`.
   - Confirm `gwtr` is aliased: `type gwtr 2>/dev/null` (run via the user's login shell — `zsh -ic 'type gwtr'` or `bash -ic 'type gwtr'`).
   - Confirm `gtr-cd` is defined.

4. **Global config.**

   ```bash
   git gtr config get --global gtr.editor.default
   git gtr config get --global gtr.ai.default
   ```

   Both should be set. If either is unset, suggest `git gtr config set --global ...`.

5. **gh CLI for `clean --merged`.**

   ```bash
   command -v gh && gh auth status
   ```

   Warn if missing or unauthenticated.

6. **Cricut workspace sanity.**

   Resolve the workspace root (see SKILL.md → "Workspace root resolution"). Report which method succeeded — `$CRICUT_WORKSPACE`, derived from cwd, or fallback path — and warn if the only signal is a fallback default that happens to exist (since that may not be the intended workspace).

   ```bash
   WS="$(resolve_cricut_workspace)" || WS=""
   if [[ -n "$WS" ]]; then
     ls -d "$WS/CricutDesignSpace" "$WS/CricutDesignSpaceCanvas" 2>/dev/null
   fi
   ```

   Report which expected repos are present. If `$WS` is empty, suggest setting `CRICUT_WORKSPACE`.

7. **Per-repo `.gtrconfig`.** For each cricut repo found in `$WS`, check `test -f <repo>/.gtrconfig` and report. Suggest `init-gtrconfig.sh` for any that are missing one but have a `package.json`.

8. **Yalc store.**

   ```bash
   ls "${HOME}/.yalc/packages/@cricut" 2>/dev/null | head
   ```

   List currently-published `@cricut/*` packages — useful to know before linking a new DS worktree.

9. **DS `dist/util` electron cache health.** For each `CricutDesignSpace` worktree (main + siblings), check the size of `dist/util` and scan for broken symlinks. The extracted electron + chromedriver cache (~380 MB) doesn't survive being shared/switched across worktrees — see [references/troubleshooting.md → DS `dist/util` electron cache](../skills/git-worktree-runner/references/troubleshooting.md#ds-distutil-electron-cache-breaks-across-worktrees).

   ```bash
   for w in "$WS/CricutDesignSpace" "$WS/CricutDesignSpace-worktrees/"*/; do
     [[ -d "$w" ]] || continue
     util="$w/dist/util"
     [[ -d "$util" ]] || continue
     size=$(du -sh "$util" 2>/dev/null | awk '{print $1}')
     broken=$(find "$util" -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l | tr -d ' ')
     printf '%s  size=%s  broken-symlinks=%s\n' "$w" "$size" "$broken"
   done
   ```

   Warn (not fail) on any worktree with `broken-symlinks > 0` — suggest `rm -rf <worktree>/dist/util`.

10. **Yalc-dirty vs truly-dirty worktrees.** Any DS worktree with active yalc links has `package.json`, `package-lock.json`, and `yalc.lock` modified by design — that's not a real dirty state. Classify each consumer worktree:

    ```bash
    YALC_RE='^.. (package\.json|package-lock\.json|yalc\.lock)$'
    for w in "$WS/CricutDesignSpace" "$WS/CricutDesignSpace-worktrees/"*/; do
      [[ -d "$w/.git" || -f "$w/.git" ]] || continue
      dirty=$(git -C "$w" status --short 2>/dev/null)
      [[ -z "$dirty" ]] && { echo "$w  clean"; continue; }
      if awk -v re="$YALC_RE" '$0 !~ re { exit 1 } END { exit 0 }' <<<"$dirty"; then
        echo "$w  yalc-dirty (routine — package.json/yalc.lock only)"
      else
        echo "$w  truly-dirty"
        sed 's/^/    /' <<<"$dirty"
      fi
    done
    ```

    Yalc-dirty is informational, not a warning. Truly-dirty is worth surfacing — those worktrees can't be cleaned via `/gwtr-clean --merged` without intervention.

Print a final summary: counts of green/warn/fail items. If anything failed, link to `references/troubleshooting.md`.
