---
name: zenify-my-terminal
description: Set up a fast, calm, focused terminal on macOS. Use when the user asks to "zenify my terminal", "make my terminal nice/pretty/awesome", "set up zsh / shell", "upgrade my terminal experience", "fast track my terminal setup", "just set me up", or "set up starship / oh-my-posh / zinit / wezterm / ghostty / cmux / alacritty / kitty / tmux". Two modes — guided (walks through choices: terminal app between WezTerm/Ghostty/cmux/Alacritty/Kitty/iTerm2/Apple Terminal, prompt between Starship/Oh My Posh, plugins, optional extras) or fast-track (one question — which terminal — then applies opinionated optimal defaults including tmux + a `claude-team` launcher so Claude Code agent-teams can spawn as visible split panes in any terminal). Writes ~/.zshrc, the chosen prompt's config, and the chosen terminal's config with macOS-specific gotchas already handled (skip `brew shellenv`, skip the deprecated `homebrew/command-not-found` tap, BSD ls vs GNU ls, sub-process PATH, zinit turbo mode for fast startup). Ends with a summary of what was installed plus the most important keyboard shortcuts.
---

# Zenify My Terminal

Walk the user through setting up a fast, calm zsh + chosen-terminal + Starship/Oh-My-Posh + zinit-managed plugins on macOS. Don't blindly run a script — ask the decisions one at a time, apply the gotchas already learned, verify, and finish with a clean cheat-sheet of how to use what you built.

**Stay terminal-neutral.** Don't push WezTerm or any other choice. The bundled assets cover seven terminals; pick the per-terminal reference based on what the user wants.

## Mode selection

After step 1 (inspecting state), ask the user which mode:

**Guided** (default): walk through every decision in step 2. Best when the user wants control, has opinions about prompt or terminal, or has an unusual existing setup.

**Fast track**: ZERO questions. Apply the exact opinionated stack the skill was built around. Triggered by phrases like "fast track", "just set me up", "use the defaults", "one-shot", "quickest setup". Best when the user trusts the skill's defaults and wants a working zenful terminal in a few minutes.

The fast-track stack is fixed — this is the "what we set up the day this skill was born" recipe, distilled. **Don't substitute or ask preference questions.** If the user wants something different, send them to guided mode.

| Decision | Fast-track value |
|---|---|
| Terminal | **WezTerm** (`brew install --cask wezterm`) |
| Font | JetBrainsMono Nerd Font |
| Color scheme | Tokyo Night Moon |
| Prompt | **Oh My Posh** with the bundled `pure.omp.json` theme |
| Plugin manager | zinit (turbo mode — `wait lucid`) |
| Big three | zsh-syntax-highlighting, zsh-autosuggestions, zsh-completions |
| Tab completion | fzf-tab |
| Directory jumper | zoxide (replaces `autojump` if present — confirm before overwriting) |
| omz snippets | `git`, `sudo`, `aws`, `kubectl` (all in — fixed) |
| Sub-process PATH | Set in `wezterm.lua` so brew tools resolve in spawned panes |
| Bottom status bar | Project name (active tab title) on left + cwd on right |
| Pane splits | `Cmd-D` / `Cmd-Shift-D` ; `Cmd-Opt-Arrow` to focus |
| Pane close | `Cmd-Shift-W` (Cmd-W still closes the whole tab, with confirm) |
| Project switcher | `Cmd-P` — fuzzy over `~/projects/*`, **tab-based** (not workspaces). Each project = a tab with shell + viddy split. |
| Live git status | `Cmd-G` — viddy pane on right (25%) |
| Lazygit | `Cmd-Shift-G` — pane below (50%) |
| Workspace nav | `Cmd-Shift-]` / `Cmd-Shift-[` cycle, `Cmd-Shift-O` overview |
| Kill workspace | `Cmd-Shift-Q` — closes every tab in the active workspace |
| Claude Code statusline | Installed **if and only if `~/.claude/` exists** — themed bundled script (default theme: `terminal` so the colors inherit the active terminal palette). Other themes: `pure`, `powerline`, `rainbow` (256-color, fixed), `minimal`. See [references/claude-statusline.md](references/claude-statusline.md). |
| Neovim + NvChad | **Not** included in fast-track — it's opt-in only since it overwrites `~/.config/nvim` and many users have an existing config. Available in guided mode (decision #7). |
| tmux + agent-teams setup | **Always installed.** `brew install tmux`, bundled `~/.tmux.conf`, and a `claude-team` zsh launcher. **If `~/.claude/` exists**, also merge `teammateMode: "tmux"` into `~/.claude/settings.json` via jq so Claude's parallel teammates spawn as split panes. Same `~/.claude/` gate as the statusline. See [references/agent-teams-tmux.md](references/agent-teams-tmux.md). |
| Verification | Run all checks in step 7 |
| Summary | Print the cheat-sheet from step 9 |

Fast-track still requires:
- The current-state inspection (step 1) — never skip this
- The `.zshrc` backup (step 4) — never skip this
- The verification (step 7) — never claim success without proof
- The post-setup summary (step 9) — the user needs to know what they got
- The `brew install` of `wezterm` cask (Gatekeeper prompt on first launch)
- The `brew install` of `viddy` and `lazygit` (without these, `Cmd-G` and `Cmd-Shift-G` won't work)
- The `brew install` of `tmux` (without it, the `claude-team` launcher and agent-teams split-pane mode can't work)
- If `~/.claude/` exists: backing up `~/.claude/settings.json` before merging `teammateMode`. **The Claude Code agent may guard self-edits to its own settings.json** — if the merge gets blocked, surface the exact `jq` command and ask the user to run it themselves; do not silently skip.

If anything fails during fast-track (a brew install errors out, a syntax check fails, the verification doesn't pass), **stop and drop into guided mode at that decision point** — don't keep barreling through silently. If the user already has a different terminal/prompt installed and configured, ask whether to overwrite or use guided mode instead.

## Workflow

### 1. Inspect the current state

Before asking any question, check what's already there. Don't ask things you can answer by looking.

```sh
echo $SHELL; which zsh; zsh --version
ls -la ~/.zshrc ~/.zshenv ~/.zprofile ~/.p10k.zsh ~/.config/starship.toml ~/.wezterm.lua ~/.config/ghostty/config ~/.config/alacritty/alacritty.toml ~/.config/kitty/kitty.conf 2>/dev/null
ls -ld /Applications/cmux.app 2>/dev/null
which brew && brew --version | head -1
for t in fzf zoxide nvim eza bat starship oh-my-posh wezterm ghostty alacritty kitty viddy lazygit jq; do which $t 2>/dev/null; done
ls ~/Library/Fonts | grep -i nerd | head -3
echo "TERM_PROGRAM=$TERM_PROGRAM"
[[ -d ~/.claude ]] && echo "Claude Code: yes ($(ls ~/.claude/statusline-command.sh 2>/dev/null && echo 'has custom statusline' || echo 'no custom statusline'))" || echo "Claude Code: no"
cat ~/.zshrc 2>/dev/null
```

If the user already has a working `.zshrc`, **read it** before deciding what to preserve.

### 2. Ask the decisions one at a time

Don't dump all questions at once. Walk through these in order. Present terminals neutrally — each has trade-offs; let the user choose based on their priorities.

1. **Terminal app** — seven real options:
   - **WezTerm** — most powerful (Lua scripting, custom workspaces/tabs/panes, project switchers). Heavier resource use. → [terminals/wezterm.md](references/terminals/wezterm.md)
   - **Ghostty** — fast, native macOS, simple `key = value` config, native tabs/splits, no scripting. Newer. → [terminals/ghostty.md](references/terminals/ghostty.md)
   - **cmux** — Ghostty-engine-based macOS app tuned for AI coding agents: vertical tabs sidebar with branch/PR/ports/notification rings, embedded WebKit browser pane, socket API. Inherits `~/.config/ghostty/config` for fonts/themes/keybindings. → [terminals/cmux.md](references/terminals/cmux.md)
   - **Kitty** — mature middle ground; native tabs/splits + Python "kittens" for extensibility. → [terminals/kitty.md](references/terminals/kitty.md)
   - **Alacritty** — minimal, GPU-accelerated, no tabs/splits (pair with tmux). → [terminals/alacritty.md](references/terminals/alacritty.md)
   - **iTerm2** — established, GUI-configured (no text config file), full-featured. → [terminals/iterm2.md](references/terminals/iterm2.md)
   - **Apple Terminal** — built-in, limited. Glyph rendering quirks; ~1.5s session-restore overhead. → [terminals/apple-terminal.md](references/terminals/apple-terminal.md)

   Briefly state the trade-offs and let the user pick. **Don't anchor to a recommendation.** If the user mentions AI coding agents (Claude Code, Codex, Aider) heavily and wants tooling around that workflow, cmux is purpose-built for it; if they want full scripting freedom, WezTerm; if they want minimum-friction native, Ghostty.

2. **Prompt** — Starship (actively maintained, simpler config, slightly faster) / Oh My Posh (125 themes including P10K-style ports, ~1s slower startup) / Powerlevel10k (in maintenance mode since 2024 — usable but not actively developed). See [references/prompts.md](references/prompts.md) for full comparison.

   **If the user picks Oh My Posh, offer to preview themes live**: run `bash <skill-dir>/scripts/preview-themes.sh` — renders a curated set of ~15 themes (including the four `powerlevel10k_*` ports) to the terminal so the user can pick by sight. Variants: `--p10k` for just the P10K-style ports, `--all` for all 125 themes, or pass theme names to preview specific ones. Then set the chosen theme's path in the `oh-my-posh init` line.
3. **Replace `autojump`?** If they have it, default to **yes** — replace with zoxide. zoxide is faster and actively developed.
4. **omz snippets** — common opt-ins: `git`, `sudo`, `aws`, `kubectl`. **Always skip `command-not-found`** — the tap is dead.
5. **Power-user extras** — opt-in (terminal-dependent — see the chosen terminal's reference for what's available):
   - All terminals: a project switcher (some need tmux as the layer, others have it native)
   - Terminals with native splits (WezTerm, Kitty, iTerm2, Ghostty): viddy git-status side pane, lazygit diff viewer
   - WezTerm only: programmable status bar with project name, kill-workspace shortcut, workspace overview launcher
6. **Claude Code statusline** (only if `[[ -d $HOME/.claude ]]` — otherwise skip silently): bundled statusline shows model name, context-window usage bar, rate-limit percentages, worktree+branch, effort level. **Five themes available** — pure (dim labels + color-coded bar), powerline (filled segments + Nerd Font arrows), rainbow (256-color fixed palette per segment — does NOT follow terminal theme), terminal (multi-color per segment using ANSI base codes — inherits terminal theme palette), minimal (model · pct · branch). Default to `terminal` (theme-aware) unless the user explicitly wants the fixed-color rainbow look. Offer to preview themes side-by-side via `bash <skill-dir>/scripts/preview-statusline-themes.sh`. See [references/claude-statusline.md](references/claude-statusline.md).
7. **Neovim + NvChad** (opt-in only — don't push it): modern Neovim setup with NvChad framework (file tree, fuzzy finder, LSP, treesitter, polished theme out of the box). Installs `neovim`, `ripgrep`, `fd`; clones the NvChad starter to `~/.config/nvim`; aliases `vim`/`vi` to `nvim`; sets `EDITOR=nvim`. Backs up any existing `~/.config/nvim` first. Only suggest this if the user explicitly asks for a "better vim", asks about Neovim, or otherwise indicates they want it. See [references/neovim-nvchad.md](references/neovim-nvchad.md).
8. **tmux for Claude Code agent teams** (in guided mode this is opt-in; in **fast-track this is always installed**): Claude's `teammateMode="tmux"` spawns parallel teammates as split panes, but only when `$TMUX` is set. Native split-pane integration exists for tmux and iTerm2 only — WezTerm/Ghostty/cmux/Kitty/Alacritty don't have it. The setup installs tmux (if missing), bundled `~/.tmux.conf` (mouse on, true color, vim-style nav, intuitive `\|`/`-` splits, minimal status bar), and a `claude-team` zsh function that ensures `$TMUX` is set before launching Claude. **If `~/.claude/` exists**, also merges `teammateMode: "tmux"` into `~/.claude/settings.json` via jq. In guided mode, only suggest the `teammateMode` merge if the user runs parallel subagents or asks about agent teams — otherwise install tmux+conf+launcher and leave `teammateMode` alone. See [references/agent-teams-tmux.md](references/agent-teams-tmux.md).

### 3. Install dependencies

Detect Apple Silicon vs Intel by checking `/opt/homebrew/bin/brew` vs `/usr/local/bin/brew`.

Always:
```sh
brew install fzf zoxide
brew install --cask font-jetbrains-mono-nerd-font
```

Prompt:
```sh
brew install starship          # OR
brew install oh-my-posh        # ← fast-track uses this
```

Terminal — install only the chosen one (if it isn't Apple Terminal, which is built-in):
```sh
brew install --cask wezterm                                    # ← fast-track uses this
brew install --cask ghostty                                    # or
brew tap manaflow-ai/cmux && brew install --cask cmux          # or — note the tap
brew install --cask alacritty                                  # or
brew install --cask kitty                                      # or
brew install --cask iterm2                                     # or
```

Power-user extras (only if opted in or in fast-track):
```sh
brew install viddy lazygit     # for git-status pane + diff viewer (fast-track requires both)
brew install tmux              # if terminal needs it for splits (Alacritty / Apple Terminal only)
brew install jq                # required by the bundled Claude Code statusline (only if Claude Code is detected)
brew install neovim ripgrep fd # if user opted into NvChad (decision #7) — not in fast-track
brew install tmux              # always in fast-track; in guided mode only if user opted in at decision #8
```

Do **not** run `brew tap homebrew/command-not-found` — it was deprecated and the tap is empty.

### 4. Back up the existing `.zshrc`

```sh
cp ~/.zshrc ~/.zshrc.bak.$(date +%Y%m%d)
diff -q ~/.zshrc ~/.zshrc.bak.$(date +%Y%m%d) && echo "OK: backup identical"
```

This is the rollback path. Don't proceed past this step until the diff confirms the backup is identical.

### 5. Write the configs

The zsh + prompt configs are terminal-agnostic. The terminal config comes from the per-terminal reference.

**Always:**
- `assets/zshrc.zsh` — generic `.zshrc` skeleton (zinit + plugins + tool init)

**Prompt** (pick one based on step 2):
- `assets/starship-pure.toml` → `~/.config/starship.toml`
- For Oh My Posh: in `.zshrc`, replace the `eval "$(starship init zsh)"` line with:
  ```sh
  eval "$(oh-my-posh init zsh --config $HOMEBREW_PREFIX/opt/oh-my-posh/themes/pure.omp.json)"
  ```

**Terminal** (pick one based on step 2):
- WezTerm: `assets/terminals/wezterm.lua` → `~/.wezterm.lua` — see [terminals/wezterm.md](references/terminals/wezterm.md)
- Ghostty: `assets/terminals/ghostty.config` → `~/.config/ghostty/config` — see [terminals/ghostty.md](references/terminals/ghostty.md)
- cmux: same `assets/terminals/ghostty.config` → `~/.config/ghostty/config` (cmux inherits it). cmux-specific behavior is in the in-app Settings UI. → see [terminals/cmux.md](references/terminals/cmux.md)
- Alacritty: `assets/terminals/alacritty.toml` → `~/.config/alacritty/alacritty.toml` — see [terminals/alacritty.md](references/terminals/alacritty.md)
- Kitty: `assets/terminals/kitty.conf` → `~/.config/kitty/kitty.conf` — see [terminals/kitty.md](references/terminals/kitty.md)
- iTerm2 / Apple Terminal: no asset file — walk the user through the manual GUI steps in their reference

**Always preserve from the existing `.zshrc`:** PATH additions for tools the user actually has installed (flutter, fnm, herd, openjdk, gcloud, bun, etc.), and any tool-specific completion sources. List them explicitly to the user before overwriting.

**Claude Code statusline** (only if `~/.claude/` exists and the user opted in, or fast-track):
```sh
cp <skill-dir>/assets/claude/statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```
Pick a theme — in guided mode, run `bash <skill-dir>/scripts/preview-statusline-themes.sh` to show all five side-by-side and let the user choose. In fast-track, default to `terminal` (so the statusline colors inherit the active terminal palette). Then merge the `statusLine` block into `~/.claude/settings.json` (use `jq`, don't overwrite the file):
```sh
THEME=terminal   # or: pure | powerline | rainbow | minimal
tmp=$(mktemp)
if [[ -f ~/.claude/settings.json ]]; then
  jq --arg cmd "sh ~/.claude/statusline-command.sh $THEME" \
     '. + {statusLine: {type: "command", command: $cmd}}' \
     ~/.claude/settings.json > "$tmp" && mv "$tmp" ~/.claude/settings.json
else
  mkdir -p ~/.claude
  printf '{"statusLine": {"type": "command", "command": "sh ~/.claude/statusline-command.sh %s"}}\n' "$THEME" > ~/.claude/settings.json
fi
```
See [references/claude-statusline.md](references/claude-statusline.md) for what each segment means, what each theme looks like, and how to customize.

**Neovim + NvChad** (only if user opted in at decision #7 — never in fast-track):
1. Back up any existing `~/.config/nvim` first (and `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim` if present). Confirm with the user before moving them.
2. `brew install neovim ripgrep fd`
3. `git clone https://github.com/NvChad/starter ~/.config/nvim --depth 1`
4. Add to `.zshrc` aliases section: `alias vim='nvim'`, `alias vi='nvim'`, `export EDITOR='nvim'`, `export VISUAL='nvim'`
5. Tell the user to run `nvim` once — first launch auto-installs plugins (~30s), then run `:MasonInstallAll` for LSP servers.

See [references/neovim-nvchad.md](references/neovim-nvchad.md) for keybindings and customization.

**tmux for Claude Code agent teams** (always in fast-track; in guided mode only if user opted in at decision #8):
1. Back up any existing `~/.tmux.conf`: `[[ -f ~/.tmux.conf ]] && cp ~/.tmux.conf ~/.tmux.conf.bak.$(date +%Y%m%d_%H%M%S)`
2. `brew install tmux` (skip if installed)
3. Copy `assets/tmux.conf` → `~/.tmux.conf`
4. Add the `claude-team` shell function from [references/agent-teams-tmux.md](references/agent-teams-tmux.md) to the aliases section of `.zshrc`
5. **Only if `~/.claude/` exists**: merge `teammateMode: "tmux"` into `~/.claude/settings.json` with jq (don't overwrite). Same `~/.claude/` gate as the Claude statusline. **Heads-up**: Claude Code's permission system may block its own agent from editing `~/.claude/settings.json`. If the jq command is blocked, surface the exact command (with the user's existing settings preserved by the jq merge) and ask the user to run it themselves — don't silently skip the step.

See [references/agent-teams-tmux.md](references/agent-teams-tmux.md) for keybindings and the rollback path.

### 6. Apply the gotchas — see [references/gotchas.md](references/gotchas.md)

Critical macOS-specific issues that will eat hours if missed. Read that file before writing the configs. Summary:

- **Don't use `brew shellenv`** — costs ~1.7s on every shell startup. Set HOMEBREW_PREFIX/CELLAR/REPOSITORY env vars manually instead.
- **Use `ls -G`, not `ls --color`** — macOS ships BSD ls, not GNU.
- **Set `LS_COLORS` with a hardcoded portable string** — coreutils isn't installed and not worth installing just for colors.
- **Use zinit turbo mode (`wait lucid`) for plugins** — synchronous loading adds ~500ms per plugin.
- **Defer slow third-party completions (gcloud, bun, entire CLI) via `zinit wait`** — these can each cost 1-2s synchronously.
- **Skip the deprecated `homebrew/command-not-found` tap** — it was removed.

Plus terminal-specific gotchas (in the per-terminal reference): WezTerm needs an explicit sub-process PATH, Apple Terminal needs `~/.bash_sessions_disable` for fast startup, etc.

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
- All other terminals: well under 1s perceived time-to-first-prompt with turbo plugins

**If startup is over 5s, profile.** Add `zmodload zsh/zprof` at top of `.zshrc`, `zprof | head -30` at end, run `zsh -i -c true`. Then revert. Common culprits: GCloud SDK completion (2.3s), `entire` completion (1.9s), `brew shellenv` (1.7s), `bun` completion (0.7s). All can be deferred via `zinit wait` — see [references/gotchas.md](references/gotchas.md).

### 8. Manual smoke test (user opens the terminal)

The user must open the chosen terminal themselves (Gatekeeper prompt on first launch for any non-builtin) and verify:
- Two-line prompt with `❯` — if boxes appear, the Nerd Font isn't being picked up
- `cd <Tab>` opens fzf-tab with directory previews
- `Ctrl-R` opens fuzzy fzf history search
- Typing a command they've used before shows a grey autosuggestion; `End` accepts it

### 9. Print the post-setup summary (REQUIRED — do not skip)

End every successful run with a structured cheat-sheet. The user has just made many choices and the skill walked through many steps — they need a single anchor message that tells them what they have and how to use it.

Format:

```markdown
## What you have now

| Component | Choice | Where it lives |
|---|---|---|
| Terminal | <chosen> | <config path> |
| Prompt | <Starship or Oh My Posh + theme> | <config path> |
| Shell config | zsh + zinit | ~/.zshrc |
| History/autosuggest | zsh-autosuggestions + zsh-syntax-highlighting | (auto-loaded by zinit) |
| Tab completion | fzf-tab + zsh-completions | (auto-loaded by zinit) |
| Directory jumper | zoxide | `z <partial>` |

(plus rows for every opt-in extra they enabled)

## Most important keyboard shortcuts

### Shell (works in any terminal)
| Key | Action |
|---|---|
| Tab | Fuzzy completion menu (fzf-tab) |
| Ctrl-R | Fuzzy history search |
| Ctrl-P / Ctrl-N | Prefix-matched history search (only commands starting with what's typed) |
| → or Ctrl-F | Accept ONE character of autosuggestion |
| Alt-F | Accept WORD of autosuggestion |
| End or Ctrl-E | Accept WHOLE autosuggestion |
| Ctrl-A | Jump to start of line |
| Ctrl-W | Delete word backward |
| Ctrl-U | Delete from cursor to start of line |
| z <partial> | Jump to frecency-matched directory |

### Terminal-specific shortcuts
(Pull from the chosen terminal's reference. Include only the keys that are actually configured for the user — don't list features they didn't opt into.)

For WezTerm with all extras: tab/pane/split/project switcher/viddy/lazygit/workspace nav/kill workspace.
For Ghostty: tab/split/zoom.
For Kitty: tab/split/layout.
For Alacritty / Apple Terminal: "Use tmux for tabs/splits — see <terminal>.md for the tmux cheat-sheet".

## Rollback

`mv ~/.zshrc.bak.YYYYMMDD ~/.zshrc` (insert today's date) restores the previous shell config. The terminal config can be deleted (~/.wezterm.lua, ~/.config/<terminal>/...) to revert that.

## What's next

- Theme tweaks: see <prompt>'s docs to swap the prompt theme; see <terminal>.md for theme browsing
- Add more plugins: `zinit light <user/repo>` then reload
- Profile if slow: `zsh -i -c 'zmodload zsh/zprof; source ~/.zshrc; zprof' | head -30`
```

Build the table from the actual decisions the user made — don't list options they declined.

## Helping users explore Oh My Posh themes

If the user picked Oh My Posh and wants to change theme later (or in-skill, before settling on one), offer the preview script:

```sh
bash <skill-dir>/scripts/preview-themes.sh        # curated representative set
bash <skill-dir>/scripts/preview-themes.sh --p10k # only the powerlevel10k_* ports
bash <skill-dir>/scripts/preview-themes.sh --all  # all 125 themes (long output)
bash <skill-dir>/scripts/preview-themes.sh atomic montys catppuccin
```

Each rendered theme appears with its name as a heading + the actual prompt. The user picks one by name; you update the `--config` path in the `oh-my-posh init` line of `~/.zshrc`.

For users coming from Powerlevel10k who want a familiar look, suggest `powerlevel10k_lean` (closest to Pure) or `powerlevel10k_rainbow` (the most colorful P10K style).

For deeper customization (custom segments, color tweaks, dropping the time module, transient prompts), see [references/prompts.md](references/prompts.md).

## What NOT to do

- Don't push a "recommended" terminal — the choice is the user's. Be neutral.
- Don't run `brew tap homebrew/command-not-found` — it's deprecated and empty.
- Don't `chsh` if `$SHELL` is already `/bin/zsh` (it usually is on modern macOS).
- Don't touch `~/.zshenv` if it exists and is root-owned — leave it alone.
- Don't suggest a 300ms startup target — Apple Terminal alone adds 1.5s. Use realistic targets per terminal app.
- Don't promise a one-shot script. The user has existing `.zshrc` integrations that will get clobbered. Walk them through, show the diff, get approval.
- Don't enable `zsh-syntax-highlighting` before `fzf-tab` — order matters and breaks completions.
- Don't call `compinit` more than once — collapse any duplicates from the user's existing config into a single call.
- Don't skip the post-setup summary in step 9 — it's how the user remembers what they got.
