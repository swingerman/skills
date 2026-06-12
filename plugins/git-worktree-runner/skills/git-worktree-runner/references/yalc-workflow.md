# Yalc Workflow (Canvas ↔ DesignSpace)

End-to-end reference for linking a `CricutDesignSpaceCanvas` (or other `@cricut/*` producer repo) worktree to a `CricutDesignSpace` consumer worktree via [yalc](https://github.com/wclr/yalc). The `/gwtr-link-ds` slash command automates most of this; read this doc when the command fails, when you're debugging a phantom mismatch, or when you need to do something the slash command doesn't cover.

## Contents

- [The basic flow](#the-basic-flow)
- [Producer commands](#producer-commands)
- [Consumer commands](#consumer-commands)
- [Verification](#verification)
- [Common gotchas](#common-gotchas)
- [Unlinking and resetting](#unlinking-and-resetting)

## The basic flow

```
┌──────────────────────────┐                  ┌─────────────────────────┐
│ CricutDesignSpaceCanvas  │                  │ CricutDesignSpace       │
│ (producer worktree)      │                  │ (consumer worktree)     │
│                          │                  │                         │
│  build + push ──────────────► ~/.yalc ──────────► yalc add (copy)     │
│                          │   global store   │   leaves yalc.sig       │
└──────────────────────────┘                  └─────────────────────────┘
```

- `yalc push` writes the published build to `~/.yalc/packages/@cricut/<lib>/`. This is **global** — any worktree of any consumer sees the same store.
- `yalc add <pkg>` (the default install mode used by `npm run yalc-add:ds`) is a **file-copy** install. It places `~/.yalc/packages/@cricut/<lib>/` into `<consumer>/node_modules/@cricut/<lib>/` and writes a marker file `yalc.sig`. **No symlink**.
- `yalc link <pkg>` (the script `yalc-link:ds`) instead creates a symlink. Either is healthy.
- Re-publishing the producer (`yalc push`) only propagates the new bits if `yalc update` is run in the consumer, **or** if the consumer was added with `--link-dep` / linked via `yalc link`. The Cricut producer scripts handle this for you when run from the producer side.

## Producer commands

Run from inside the producer worktree (e.g. a `CricutDesignSpaceCanvas` worktree).

| Command | Effect |
|---|---|
| `npm run build` | Build every `@cricut/canvas-*` lib (no push, no link). Slow — only do this if you want to know the build works without touching consumers. |
| `npm run publish:<lib>` | Build a single lib and `yalc push` it to `~/.yalc`. Useful for tight iteration on one lib. |
| `npm run publish:all` / `publish:all-webw` | Same, but for every lib. |
| `npm run yalc-add:ds` | For each lib in this producer, run `yalc add <pkg>` in the DS consumer (resolved via `git rev-parse --git-common-dir` by default, or `DS_PATH` if set). **Does not build** — assumes the libs are already in `~/.yalc`. |
| `npm run build:yalc:link` / `build:yalc:add` | Build, push, **and** add/link in the consumer in one shot. Slow (5–30 min for the full canvas tree) — use when bootstrapping a fresh DS worktree. |
| `DS_PATH=<path> npm run yalc-add:ds` | Override the consumer location. Required when linking a non-default DS worktree. |
| `npm run build-watch` | Rebuild incrementally on every change. Pair with a separate `yalc push` cycle (or use the existing watcher script if one exists). |

## Consumer commands

Run from inside the consumer worktree (`CricutDesignSpace` or a worktree of it).

| Command | Effect |
|---|---|
| `yalc add @cricut/<lib>` | Pull whatever is in `~/.yalc` for that lib into `node_modules`. File-copy install. |
| `yalc link @cricut/<lib>` | Same but as a symlink. |
| `yalc update` | Re-pull every yalc-installed package from `~/.yalc`. Run after the producer pushed a new build. |
| `yalc check` | List what's currently yalc-managed in this consumer. |
| `yalc remove @cricut/<lib>` | Restore the npm-registry version. Run `npm i --legacy-peer-deps` after. |
| `yalc remove --all` | Same for every yalc-installed package. |

## Verification

After linking, confirm:

```bash
# What yalc thinks is installed in this consumer.
cd <consumer-worktree>
yalc check

# Per-package physical state — the .sig file is yalc's marker.
ls node_modules/@cricut/canvas-renderer/yalc.sig 2>/dev/null && echo "linked (file-copy)"
[[ -L node_modules/@cricut/canvas-renderer ]] && echo "linked (symlink)"
```

The `/gwtr-link-ds` command does this for every package the producer owns, classified as:

- `✓ yalc-add: file-copy, yalc.sig present`
- `✓ yalc-link: symlink → ~/.yalc/...`
- `?` no presence in consumer (run `yalc add`)
- `✗` symlink pointing somewhere other than `~/.yalc` (bad state — restore from npm)

## Common gotchas

- **Fresh DS worktree, `yalc-add:ds` does nothing useful.** If `~/.yalc` has stale or partial canvas libs, the consumer pulls those. Symptom: DS build fails with type errors that don't match the source. Fix: run `npm run build:yalc:link` (or `build:yalc:add`) from the producer to rebuild every lib and push fresh. Surfaced by `/gwtr-link-ds` when the consumer has no `yalc.sig` files at all.
- **`@cricut/*` versions look "exact" in `package.json` after `yalc add`.** `yalc add` rewrites the dep entry to `file:.yalc/...`. This is expected — leave it alone, `yalc remove` restores the registry pin. Don't commit the change. `/gwtr-rm` knows to treat `package.json` / `package-lock.json` / `yalc.lock` modifications as routine yalc state.
- **`yalc push` from inside a worktree pushes that worktree's build.** `~/.yalc` is global — last writer wins. If two canvas worktrees have different code, the last `yalc push` overrides. Stop publishing from the "wrong" worktree, then republish from the right one.
- **Phantom mismatch in DS.** Build error references a function name that doesn't exist in the canvas source you're looking at. Suspect a stale `~/.yalc` entry from a different worktree. Run `ls ~/.yalc/packages/@cricut/<lib>/package.json` to see when it was last published, and `cat ~/.yalc/packages/@cricut/<lib>/dist/...` to see what's actually shipped.
- **DS `dist/util/` electron cache breaks across worktrees.** Not a yalc issue but often surfaces during yalc-driven debugging. See [troubleshooting.md → DS `dist/util` electron cache](troubleshooting.md#ds-distutil-electron-cache-breaks-across-worktrees).

## Unlinking and resetting

Restore the registry version of one package in a consumer:

```bash
cd <consumer-worktree>
yalc remove @cricut/canvas-renderer
npm i --legacy-peer-deps
```

Reset the entire consumer to the registry:

```bash
cd <consumer-worktree>
yalc remove --all
npm i --legacy-peer-deps
```

Wipe the global yalc store (rarely needed — usually a per-package remove is enough):

```bash
rm -rf ~/.yalc
# Then republish from the producer.
```
