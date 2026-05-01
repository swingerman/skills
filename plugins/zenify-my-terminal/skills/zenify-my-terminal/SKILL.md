---
name: zenify-my-terminal
description: Set up a fast, calm, focused terminal on macOS. Use when the user asks to "zenify my terminal", "make my terminal nice/pretty/awesome", "set up zsh / shell", "upgrade my terminal experience", "switch to wezterm", or "set up starship / oh-my-posh / zinit". Walks through decisions (terminal app, prompt, plugins, optional WezTerm extras), then writes ~/.zshrc, ~/.config/starship.toml (or oh-my-posh equivalent), and ~/.wezterm.lua — with macOS-specific gotchas already handled (skip `brew shellenv`, skip the deprecated `homebrew/command-not-found` tap, BSD ls vs GNU ls, set sub-process PATH for WezTerm, use zinit turbo mode for fast startup).
---

# Zenify My Terminal

Walk the user through setting up a fast, calm zsh + WezTerm + Starship/Oh-My-Posh + zinit-managed plugins on macOS. Don't blindly run a script — ask the decisions one at a time, apply the gotchas already learned, and verify before claiming done.

## Workflow

### 1. Inspect the current state

Before asking any question, check what's already there. Don't ask things you can answer by looking.

```sh
echo $SHELL; which zsh; zsh --version
ls -la ~/.zshrc ~/.zshenv ~/.zprofile ~/.p10k.zsh ~/.config/starship.toml ~/.wezterm.lua 2>/dev/null
which brew && brew --version | head -1
for t in fzf zoxide nvim eza bat starship oh-my-posh wezterm viddy lazygit; do which $t 2>/dev/null; done
ls ~/Library/Fonts | grep -i nerd | head -3
echo "TERM_PROGRAM=$TERM_PROGRAM"
cat ~/.zshrc 2>/dev/null
```

If the user already has a working `.zshrc`, **read it** before deciding what to preserve.

### 2. Ask the decisions one at a time

Don't dump all questions at once. Walk through these in order, with the recommended default highlighted.

1. **Terminal app** — Apple Terminal / Ghostty / Alacritty / **WezTerm** (recommended). Apple Terminal won't render Nerd Font glyphs cleanly; flag this if they want to stay on it.
2. **Prompt** — **Starship** (recommended: actively maintained, simpler config) / Oh My Posh (more themes, ~1s slower startup) / Powerlevel10k (in maintenance mode since 2024).
3. **Replace `autojump`?** If they have it, default to **yes** — replace with zoxide. zoxide is faster and actively developed.
4. **omz snippets** — default in: `git`, `sudo`. Optional: `aws`, `kubectl` (only if they use them; cost startup time). **Always skip `command-not-found`** — the tap is dead.
5. **WezTerm extras** — opt-in: project switcher (`Cmd-P` over `~/projects/*`), viddy git-status side pane (`Cmd-G`), lazygit diff viewer (`Cmd-Shift-G`), bottom status bar (project name + cwd), kill-workspace shortcut (`Cmd-Shift-Q`). See [references/wezterm-extras.md](references/wezterm-extras.md).
6. **Project switcher container — TABS or WORKSPACES?** (only ask if user opted into the project switcher)
   - **Tabs (recommended, default)**: each project = one tab in the current window. Cmd-1..9 to switch. Multi-window works because tabs are window-local.
   - **Workspaces**: each project = a named workspace. Looks tidier in single-window setups, but **breaks with multi-window**: workspaces are global in WezTerm — switching one window's workspace hides other windows attached to the previous workspace. The bundled config uses tabs by default. Only suggest workspaces if the user is sure they'll always work in a single WezTerm window. See [gotchas.md](references/gotchas.md#workspaces-are-global--multi-window--workspaces-dont-combine).

### 3. Install dependencies

Detect Apple Silicon vs Intel by checking `/opt/homebrew/bin/brew` vs `/usr/local/bin/brew`. The PATH gotcha (step 6 below) cares about this.

```sh
brew install fzf zoxide
brew install --cask wezterm font-jetbrains-mono-nerd-font
# Prompt:
brew install starship          # or:
brew install oh-my-posh
# WezTerm extras (only if user opted in):
brew install viddy lazygit
```

Do **not** run `brew tap homebrew/command-not-found` — it was deprecated and the tap is empty. Skip the `OMZP::command-not-found` snippet entirely on macOS.

### 4. Back up the existing `.zshrc`

```sh
cp ~/.zshrc ~/.zshrc.bak.$(date +%Y%m%d)
diff -q ~/.zshrc ~/.zshrc.bak.$(date +%Y%m%d) && echo "OK: backup identical"
```

This is the rollback path. Don't proceed past this step until the diff confirms the backup is identical.

### 5. Write the configs

Use the bundled templates as the base, then layer in the user's preserved integrations and chosen extras:

- `assets/zshrc.zsh` — generic `.zshrc` skeleton (zinit + plugins + tool init)
- `assets/starship-pure.toml` — Starship pure-style preset (skip if user picked Oh My Posh)
- `assets/wezterm-base.lua` — WezTerm base config (font, theme, PATH, tab/split/pane keys, status bar)

For Oh My Posh instead of Starship: replace the `eval "$(starship init zsh)"` line in `.zshrc` with:
```sh
eval "$(oh-my-posh init zsh --config /usr/local/opt/oh-my-posh/themes/pure.omp.json)"
```
(Adjust path for Apple Silicon: `/opt/homebrew/opt/...`.)

**Always preserve from the existing `.zshrc`:** PATH additions for tools the user actually has installed (flutter, fnm, herd, openjdk, gcloud, bun, etc.), and any tool-specific completion sources. List them explicitly to the user before overwriting.

### 6. Apply the gotchas — see [references/gotchas.md](references/gotchas.md)

Critical macOS-specific issues that will eat hours if missed. Read that file before writing the configs. Summary:

- **Don't use `brew shellenv`** — costs ~1.7s on every shell startup. Set HOMEBREW_PREFIX/CELLAR/REPOSITORY env vars manually instead. Brew binaries are already on PATH via `/etc/paths`.
- **Use `ls -G`, not `ls --color`** — macOS ships BSD ls, not GNU.
- **Set `LS_COLORS` with a hardcoded portable string** — coreutils isn't installed and not worth installing just for colors.
- **Use zinit turbo mode (`wait lucid`) for plugins** — synchronous loading adds ~500ms per plugin.
- **Defer slow third-party completions (gcloud, bun, entire CLI) via `zinit wait`** — these can each cost 1-2s synchronously.
- **WezTerm spawns subprocesses with minimal PATH** — set `config.set_environment_variables = { PATH = '/usr/local/bin:...' }` or brew tools won't resolve in panes.
- **Skip the deprecated `homebrew/command-not-found` tap** — it was removed.

### 7. Verify before claiming done

Run these and inspect the output. **Never** declare success without seeing the verification pass.

```sh
zsh -n ~/.zshrc && echo "OK: syntax clean"

# Trigger zinit bootstrap (first run only — clones plugins, can take 30-60s)
zsh -i -c 'echo BOOTSTRAP_OK' 2>&1 | tail -5

# Smoke-test a fresh shell
zsh -i -c 'echo OK'

# Verify each preserved integration still resolves
zsh -i -c 'for t in flutter fnm bun gcloud git; do command -v $t >/dev/null && echo "OK $t" || echo "GONE $t"; done'

# Verify the prompt renders
zsh -i -c 'starship prompt --status=0' | head -3   # or oh-my-posh equivalent

# Cold startup time (3 runs, measure from /bin/sh to avoid wrapper noise)
for i in 1 2 3; do /bin/sh -c 'TIMEFORMAT="%R s"; time zsh -i -c exit' 2>&1 | tail -1; done
```

Realistic targets:
- Apple Terminal: ~2-3s (Apple's session restore is ~1.5s of that — unavoidable there)
- WezTerm: well under 1s perceived time-to-first-prompt (turbo plugins load in background)

**If startup is over 5s, profile.** Add `zmodload zsh/zprof` at top of `.zshrc`, `zprof | head -30` at end, run `zsh -i -c true`. Then revert. Common culprits: GCloud SDK completion (2.3s), `entire` completion (1.9s), `brew shellenv` (1.7s), `bun` completion (0.7s). All can be deferred via `zinit wait` — see [references/gotchas.md](references/gotchas.md).

### 8. Hand off the manual smoke test

The user must open WezTerm themselves (Gatekeeper prompt on first launch) and verify:
- Two-line prompt with `❯` (no missing-glyph boxes — if boxes appear, the Nerd Font isn't being picked up)
- `cd <Tab>` opens fzf-tab with directory previews
- `Ctrl-R` opens fuzzy fzf history search
- Typing a command they've used before shows a grey autosuggestion; `End` accepts it

Tell them the rollback path: `mv ~/.zshrc.bak.YYYYMMDD ~/.zshrc`.

## Optional WezTerm extras

These are popular add-ons. Only add if the user asks for them or opts in during step 2. Full configs in [references/wezterm-extras.md](references/wezterm-extras.md):

- **Project switcher** (`Cmd-P`): fuzzy picker over `~/projects/*` subdirs; selecting one creates/switches to a workspace named after the project, with main shell + `viddy git status` side pane.
- **Live git-status pane** (`Cmd-G`): splits a 25%-width right pane running `viddy --interval 2 --differences git status -s`.
- **Lazygit pane** (`Cmd-Shift-G`): splits 50% below with full diff viewer + stage/commit/branch.
- **Bottom status bar**: workspace name on the left, cwd on the right.
- **Kill workspace** (`Cmd-Shift-Q`): closes every tab in the active workspace at once.
- **Workspace overview** (`Cmd-Shift-O`): fuzzy launcher over open workspaces.
- **Workspace-switch toast**: 3s notification when you switch workspaces ("don't lose track of your previous shell").

## What NOT to do

- Don't run `brew tap homebrew/command-not-found` — it's deprecated and empty.
- Don't `chsh` if `$SHELL` is already `/bin/zsh` (it usually is on modern macOS).
- Don't touch `~/.zshenv` if it exists and is root-owned — leave it alone.
- Don't suggest a 300ms startup target — Apple Terminal alone adds 1.5s. Use realistic targets per terminal app.
- Don't promise a one-shot script. The user has existing `.zshrc` integrations that will get clobbered. Walk them through, show the diff, get approval.
- Don't enable `zsh-syntax-highlighting` before `fzf-tab` — order matters and breaks completions.
- Don't call `compinit` more than once — collapse any duplicates from the user's existing config into a single call.
