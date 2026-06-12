---
description: Link the current canvas worktree to a CricutDesignSpace consumer worktree via yalc (DS_PATH).
argument-hint: "[ds-worktree-name]"
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

Link the **current canvas-style worktree** (one that publishes `@cricut/canvas-*` libs) to a chosen **CricutDesignSpace consumer worktree** by running `DS_PATH=<chosen> npm run yalc-add:ds`.

Arguments: `$ARGUMENTS` (optional DS worktree name; if omitted, present a picker)

## Steps

### 1. Verify the current repo is a yalc producer

The actual capability test is whether `package.json` defines any of the known yalc-link scripts. Probe in this order and remember which one was found — the choice matters in step 4:

```bash
node -e '
const p=require("./package.json");
const wanted=["build:yalc:link","build:yalc:add","yalc-link:ds","yalc-add:ds"];
const found=wanted.find(s=>p.scripts&&p.scripts[s]);
process.stdout.write(found||"");
'
```

Stop if the output is empty.

Script preference (in the order tried above):
1. `build:yalc:link` / `build:yalc:add` — **builds and pushes all libs, then adds them**. Prefer this when the DS worktree is fresh (no `node_modules/@cricut/*/yalc.sig` files).
2. `yalc-link:ds` / `yalc-add:ds` — registers what's already in the `~/.yalc` store. Faster, but only works if the libs are already published.

This single check is enough — any repo defining one of these scripts is a valid producer. Don't gate on a hardcoded allowlist of repo names.

### 2. Discover available DS consumer worktrees

Resolve the Cricut workspace root using the snippet from SKILL.md → "Workspace root resolution" (`$CRICUT_WORKSPACE` → derive from current repo's parent → common fallbacks). The current cwd is a producer repo, so its parent is the workspace root in the common case.

Build the candidate list:

```bash
ls -d "$WS/CricutDesignSpace" "$WS/CricutDesignSpace-worktrees/"*/ 2>/dev/null
```

If `$WS` could not be resolved, ask the user where their `CricutDesignSpace` checkout(s) live and suggest setting `CRICUT_WORKSPACE` for next time.

Filter to entries that are valid git worktrees: for each candidate, `git -C <path> rev-parse --git-dir` must succeed.

For each, capture:
- absolute path
- branch name (`git -C <path> branch --show-current`)
- short status (`git -C <path> status --short | wc -l` → number of dirty files)

### 3. Pick a target

- If `$1` is provided and uniquely matches one candidate by basename or branch name, use it.
- Otherwise, present the candidates with `AskUserQuestion`, showing path + branch + dirty-file count. Include the main checkout as the first option labeled "main repo (default)".

### 4. Run the link

Check the chosen consumer for prior yalc state — `yalc add` does a **file-copy install** by default (leaves `<consumer>/node_modules/<pkg>/yalc.sig`), so absence of `yalc.sig` means the DS worktree has never been linked:

```bash
ls "<chosen-absolute-path>"/node_modules/@cricut/*/yalc.sig 2>/dev/null | head -1
```

If empty **and** the producer offers a `build:yalc:link` / `build:yalc:add` script (from step 1), prefer it — it builds every lib and pushes the fresh artifact into `~/.yalc` before adding. This can take 5–30 min in the canvas repo; surface a one-line warning and run in the background:

```bash
DS_PATH="<chosen-absolute-path>" npm run build:yalc:link
```

Otherwise (libs already published, or only the `yalc-add:ds` flavor is available):

```bash
DS_PATH="<chosen-absolute-path>" npm run yalc-add:ds
```

Stream output. If it fails because no `@cricut/canvas-*` packages have been published yet, suggest:

```bash
npm run publish:core            # or publish:canvas-renderer, publish:all-webw, etc.
```

and re-run the link.

### 5. Verify and remind

After success, verify links **for the packages this producer actually owns**. Derive the package list from the producer's own `package.json` (root or workspace libs), not from `~/.yalc/packages/@cricut`, which contains everything the user has published from any repo.

```bash
# Collect this producer's @cricut/* package names.
collect_pkgs() {
  # 1. Single-package: root package.json with a @cricut/* name.
  root_name=$(node -e 'try{const p=require("./package.json");process.stdout.write(p.name||"")}catch(_){}' 2>/dev/null)
  if [[ "$root_name" == @cricut/* ]]; then
    echo "$root_name"; return
  fi

  # 2. Nx-style workspace: dist/libs/*/package.json (built) or libs/*/package.json (source).
  for pj in dist/libs/*/package.json libs/*/package.json; do
    [[ -f "$pj" ]] || continue
    name=$(node -e "try{process.stdout.write(require('$PWD/$pj').name||'')}catch(_){}" 2>/dev/null)
    [[ "$name" == @cricut/* ]] && echo "$name"
  done | sort -u
}

PRODUCER_PKGS=$(collect_pkgs)
[[ -z "$PRODUCER_PKGS" ]] && {
  echo "Could not derive producer package names from package.json — skipping verification."
  exit 0
}

# Check each one in the consumer. `yalc add` is file-copy install by default
# (leaves yalc.sig); `yalc link` produces a symlink. Both are healthy.
while IFS= read -r pkg; do
  link="<chosen-absolute-path>/node_modules/$pkg"
  if [[ -f "$link/yalc.sig" ]]; then
    echo "✓ $pkg  (yalc-add: file-copy, yalc.sig present)"
  elif [[ -L "$link" ]]; then
    target=$(readlink "$link")
    case "$target" in
      *.yalc/*|*/yalc/*) echo "✓ $pkg → $target  (yalc-link: symlink)" ;;
      *) echo "✗ $pkg → $target  (symlink but not a yalc target — bad state)" ;;
    esac
  elif [[ -d "$link" ]]; then
    echo "? $pkg  (directory exists but no yalc.sig — may be the npm version, not yalc-linked)"
  else
    echo "? $pkg  (not present in consumer — run: yalc add $pkg from <chosen-absolute-path>)"
  fi
done <<< "$PRODUCER_PKGS"
```

If `PRODUCER_PKGS` is empty, the producer hasn't published its libs yet (no `dist/libs/*/package.json`) — suggest `npm run build` followed by `npm run publish:<lib>` and re-run the link.

Tell the user:

- To start a watcher in this canvas worktree: `npm run build-watch`
- To rebuild a single lib + push: `npm run publish:<lib>`
- To unlink later: `cd "<chosen-path>" && yalc remove @cricut/<package> && npm i --legacy-peer-deps`

## Notes

- `yalc push` writes to `~/.yalc`, so this link survives switching between producer worktrees.
- The repo's existing `yalc-add:ds` script resolves DS via `git rev-parse --git-common-dir` by default — that's what `DS_PATH` overrides.
- Never set `DS_PATH` to a non-worktree directory (e.g. an arbitrary clone) without asking — yalc will write into its `node_modules` regardless.
