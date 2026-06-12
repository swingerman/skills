# Manual install reference

The `install-gtr.sh` (macOS/Linux) and `install-gtr.ps1` (Windows) scripts handle the common case. If they fail or the user wants a different layout, here are all the documented methods.

Source: https://github.com/coderabbitai/git-worktree-runner

## 1. Homebrew (macOS)

```bash
brew tap coderabbitai/tap
brew install git-gtr
```

Easiest. Updates with `brew upgrade git-gtr`.

## 2. Script installer (macOS / Linux)

```bash
git clone https://github.com/coderabbitai/git-worktree-runner.git
cd git-worktree-runner
./install.sh
```

The upstream `install.sh` may prompt for `sudo` to write to `/usr/local/bin`.

## 3. Manual symlink with sudo

```bash
git clone https://github.com/coderabbitai/git-worktree-runner.git ~/git-worktree-runner
sudo mkdir -p /usr/local/bin
sudo ln -s "$HOME/git-worktree-runner/bin/git-gtr" /usr/local/bin/git-gtr
```

## 4. User-local install (no sudo) — what `install-gtr.sh` uses

```bash
git clone https://github.com/coderabbitai/git-worktree-runner.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}/git-worktree-runner"
mkdir -p ~/.local/bin
ln -s "${XDG_DATA_HOME:-$HOME/.local/share}/git-worktree-runner/bin/git-gtr" \
      ~/.local/bin/git-gtr
```

Make sure `~/.local/bin` is on `PATH`:

```bash
# zsh / bash
export PATH="$HOME/.local/bin:$PATH"
```

## Windows

git-gtr is a bash script — Windows needs a POSIX shell. Two supported routes:

### Git for Windows (Git Bash)

Recommended for users who already have Git for Windows installed.

1. Verify Git Bash is available: `bash --version` in PowerShell or cmd.
2. Run the PowerShell installer:

   ```powershell
   .\.agents\skills\git-worktree-runner\scripts\install-gtr.ps1
   ```

   This clones `coderabbitai/git-worktree-runner` to `%LOCALAPPDATA%\git-worktree-runner` and adds `bin\` to the user-level `PATH`. No admin / Developer Mode required (no symlinks).

3. **Open a new PowerShell window** so the PATH change is picked up, then verify: `git gtr version`.

4. Add the `gwtr` PowerShell function:

   ```powershell
   .\.agents\skills\git-worktree-runner\scripts\install-alias.ps1
   ```

5. **Optional**: also run `bash install-alias.sh` inside Git Bash to get the `gtr-cd` navigation helper in that shell.

### WSL

If the user already does most of their dev work in WSL, treat the WSL distro as Linux and follow the macOS/Linux instructions above. There is no benefit to mixing WSL and Windows-side installs.

## Updating

- Homebrew: `brew upgrade git-gtr`
- Cloned install (macOS/Linux): `git -C "${XDG_DATA_HOME:-$HOME/.local/share}/git-worktree-runner" pull`
- Cloned install (Windows): `git -C "$env:LOCALAPPDATA\git-worktree-runner" pull` in PowerShell
- Or just re-run `install-gtr.sh -Force` / `install-gtr.ps1 -Force`.

## Uninstall

- Homebrew: `brew uninstall git-gtr && brew untap coderabbitai/tap`
- Manual (macOS/Linux): remove the symlink in `~/.local/bin` (or `/usr/local/bin`) and the cloned directory.
- Manual (Windows): remove `%LOCALAPPDATA%\git-worktree-runner` and the corresponding entry from your user `PATH` (System Properties → Environment Variables → User variables → Path).

## Prerequisites

- **Git** ≥ 2.17
- **Bash** ≥ 3.2 (4.0+ recommended for some features)
- macOS, Linux, or Windows + Git for Windows / WSL

`git gtr doctor` will flag any missing prereqs.
