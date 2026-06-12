# Troubleshooting

## Contents

- [`command not found: git-gtr` after install](#command-not-found-git-gtr-after-install)
- [`git gtr clean --merged` fails or skips everything](#git-gtr-clean---merged-fails-or-skips-everything)
- [`Worktree not found for branch` from `editor`/`rm`/`go`](#worktree-not-found-for-branch-from-editorrmgo)
- [Parallel `git gtr new` races on `.git/config`](#parallel-git-gtr-new-races-on-gitconfig)
- [DS `dist/util` electron cache breaks across worktrees](#ds-distutil-electron-cache-breaks-across-worktrees)
- [Stale worktree refs after manual `rm -rf`](#stale-worktree-refs-after-manual-rm--rf)
- [`postCreate` hook fails](#postcreate-hook-fails)
- [Yalc symlinks pointing to the wrong consumer (Cricut canvas)](#yalc-symlinks-pointing-to-the-wrong-consumer-cricut-canvas)
- [`Branch already checked out in another worktree`](#branch-already-checked-out-in-another-worktree)
- [`git gtr` is slow on first run after a long break](#git-gtr-is-slow-on-first-run-after-a-long-break)
- [Windows-specific issues](#windows-specific-issues)
- [Reset everything](#reset-everything)

## `command not found: git-gtr` after install

PATH issue. Check the install location:

```bash
ls -l ~/.local/bin/git-gtr /usr/local/bin/git-gtr 2>/dev/null
```

If the binary is in `~/.local/bin`, ensure it's on PATH:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Homebrew installs land in `$(brew --prefix)/bin`, which is normally already on PATH. If `brew doctor` complains, fix that first.

## `git gtr clean --merged` fails or skips everything

`--merged` uses the GitHub CLI to check PR state. Verify:

```bash
gh --version
gh auth status
```

If `gh` is missing, install it for the current platform:

| Platform | Command |
|---|---|
| macOS (Homebrew) | `brew install gh` |
| Debian / Ubuntu | `sudo apt install gh` (see [cli/cli install docs](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) for the apt repo setup) |
| Fedora / RHEL | `sudo dnf install gh` |
| Arch | `sudo pacman -S github-cli` |
| Other Linux | Follow [cli/cli install docs](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) |

Then authenticate: `gh auth login`.

If `gh` is installed but unauthenticated, just run `gh auth login`.

`clean --merged` also skips worktrees that have uncommitted or untracked files. Run with `--dry-run` to see why each worktree was kept.

## `Worktree not found for branch` from `editor`/`rm`/`go`

`git gtr editor <branch>`, `git gtr rm <branch>`, and `git gtr go <branch>` resolve worktrees relative to the **current** repo's worktree list. If you're sitting inside a sibling worktree and ask gtr about a different branch, it returns:

```
[x] Worktree not found for branch: <branch>
```

even though the worktree exists. Fix: `cd` to the main checkout (or any worktree that lists the target) before running the command.

```bash
# Jump to the main checkout from wherever you are.
cd "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
git gtr editor <branch>
```

The Cricut slash commands (`/gwtr-rm`, `/gwtr-new`, etc.) do this automatically.

## Parallel `git gtr new` races on `.git/config`

Running two `git gtr new` calls in parallel (e.g. two background Bash invocations) can race on `.git/config`. Git's own `worktree add` holds a brief lock, but the long `postCreate` `npm install` runs after the lock releases — the second invocation can start its worktree-add before the first has fully settled, and the second postinstall sometimes bails or completes silently into a half-set-up worktree.

**Always serialize**:

```bash
git gtr new branch-a --from origin/main && git gtr new branch-b --from origin/main
# not: git gtr new branch-a & git gtr new branch-b
```

If you suspect this happened, inspect the second worktree's `node_modules` size and run `npm install` again from inside it.

## DS `dist/util` electron cache breaks across worktrees

Each `CricutDesignSpace` worktree builds its own `dist/util/` directory holding the extracted Electron + chromedriver cache (~380 MB). The internal symlinks don't survive being shared/switched across worktrees — symptoms include Electron failing to start, ESM module-not-found errors during dev, or broken-symlink warnings.

Fix: clear the cache in each affected DS worktree and let the next build re-extract.

```bash
for w in "$CRICUT_WORKSPACE"/CricutDesignSpace "$CRICUT_WORKSPACE"/CricutDesignSpace-worktrees/*/; do
  [[ -d "$w/dist/util" ]] && rm -rf "$w/dist/util"
done
```

This is safe — `dist/util` is regenerated on the next build. Worth running before publishing/QA when multiple DS worktrees have been active.

## Stale worktree refs after manual `rm -rf`

If someone deleted a worktree directory without `git gtr rm`, git still tracks it:

```bash
git worktree list           # shows the ghost
git gtr clean               # prunes stale refs and empty dirs
```

If `git gtr clean` doesn't remove it, fall back to:

```bash
git worktree prune
```

## `postCreate` hook fails

`git gtr new` runs the hook from the new worktree's directory. Common failures:

- **`npm: command not found`** — Node not installed or not on PATH for the non-login shell git-gtr spawns. Install Node and ensure `nvm`/`fnm` initializes for non-interactive shells, or switch to a system Node install.
- **Auth failure on `npm install`** — private `@cricut` packages need a token in `~/.npmrc`. The token is per-user, not per-worktree, so this is usually a one-time setup issue.
- **Hook command needs approval** — git-gtr asks `git gtr trust` to approve. Run `git gtr trust` and re-run `git gtr new`.

To skip the hook for a single create: `git gtr new <branch> --no-hooks`.

## Yalc symlinks pointing to the wrong consumer (Cricut canvas)

`yalc-add:ds` and `yalc-link:ds` resolve the consumer via `git rev-parse --git-common-dir`, so they default to the **main** `CricutDesignSpace` checkout — not a sibling worktree. To target a specific worktree:

```bash
DS_PATH=$CRICUT_WORKSPACE/CricutDesignSpace-worktrees/my-feature \
  npm run yalc-add:ds
# Or with an explicit path: ~/src/cricut/CricutDesignSpace-worktrees/my-feature
```

If a "phantom" change in `CricutDesignSpace` doesn't match the source you're looking at, suspect a stale yalc-linked library:

```bash
ls -l node_modules/@cricut/<lib>      # check for a yalc symlink
```

Rebuild and republish from the producing repo (`npm run publish:<lib>`) — `yalc push` writes to `~/.yalc` and propagates to all consumers.

## "Branch already checked out in another worktree"

Git refuses to check out a branch in two worktrees by default. Either:

- Switch to the existing worktree (`git gtr go <branch>`), or
- Force a parallel variant (`git gtr new <branch> --force`) — only do this if you actually want two working copies of the same branch.

## `git gtr` is slow on first run after a long break

`git gtr new` does a `git fetch` by default. If your default remote is slow or unreachable, pass `--no-fetch` to skip it.

## Windows-specific issues

### `git: 'gtr' is not a git command` in PowerShell after `install-gtr.ps1`

The PATH change made by `install-gtr.ps1` only takes effect in **new** shells. Open a new PowerShell window and try again. To verify the entry was saved:

```powershell
[Environment]::GetEnvironmentVariable("Path","User") -split ';' | Select-String "git-worktree-runner"
```

### `bash: command not found` when running `git gtr`

Even after PATH is correct, git on Windows runs `git-gtr` via the bash interpreter shipped with Git for Windows. If `bash` is not on PATH (e.g. you have a non-Git-for-Windows git like the Visual Studio bundled one), git can't execute the script.

Fix: install [Git for Windows](https://git-scm.com/download/win) and make sure its `bin` directory is ahead of any other git on PATH.

### `gwtr` works in Git Bash but not in PowerShell (or vice versa)

`gwtr` is registered separately in each shell:

- Bash / zsh: by `install-alias.sh` (writes to `~/.bashrc` or `~/.zshrc`)
- PowerShell: by `install-alias.ps1` (writes to `$PROFILE`)

Run whichever one matches the shell you're in. Power users who use both can run both.

### `gtr-cd` is not defined in PowerShell

The upstream `git gtr init <shell>` only emits bash, zsh, and fish helpers. PowerShell has no native `gtr-cd`. Use:

```powershell
Set-Location (git gtr go <branch>)
```

Or run a full Git Bash session for navigation work.

### Path delimiters in `.gtrconfig`

`init-gtrconfig.sh` writes POSIX-style commands (e.g. `npm install`). These work in Git Bash and WSL but not in plain `cmd.exe`. If a `postCreate` hook needs to run from `cmd.exe`, edit `.gtrconfig` to use a Windows-friendly form. PowerShell users typically run `git gtr new` itself from PowerShell but the `postCreate` hook executes via the bash interpreter Git for Windows ships, so the default usually works.

## Reset everything

If a machine's gtr install is in a bad state:

**macOS / Linux:**
```bash
# 1. Remove binary
rm -f ~/.local/bin/git-gtr /usr/local/bin/git-gtr  # one of these
brew uninstall git-gtr 2>/dev/null || true

# 2. Remove cloned source (if user-local install)
rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/git-worktree-runner"

# 3. Remove global config
rm -rf ~/.config/git-gtr

# 4. Re-run install-gtr.sh
```

**Windows (PowerShell):**
```powershell
# 1. Remove cloned source
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\git-worktree-runner"

# 2. Remove the user-PATH entry
$p = [Environment]::GetEnvironmentVariable("Path","User")
$p = ($p -split ';' | Where-Object { $_ -notlike "*git-worktree-runner*" }) -join ';'
[Environment]::SetEnvironmentVariable("Path", $p, "User")

# 3. Remove global config
Remove-Item -Recurse -Force "$env:USERPROFILE\.config\git-gtr" -ErrorAction SilentlyContinue

# 4. Open a new PowerShell window, then re-run install-gtr.ps1
```

Per-repo `.gtrconfig` and existing worktrees are untouched by the above.
