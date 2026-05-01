# macOS Gotchas — Lessons Learned

Each of these costs hours if you discover them at debug time. Apply them up front.

## Performance gotchas (the big ones)

### `brew shellenv` costs ~1.7s per shell startup

`eval "$(brew shellenv)"` invokes a Ruby process every time. On Intel Macs, `/usr/local/bin` is already in PATH via `/etc/paths`, so `brew shellenv` is unnecessary for getting brew binaries to resolve.

**Fix:** Set the few env vars manually.
```sh
if [[ -x /usr/local/bin/brew ]]; then
  export HOMEBREW_PREFIX="/usr/local"
  export HOMEBREW_CELLAR="/usr/local/Cellar"
  export HOMEBREW_REPOSITORY="/usr/local/Homebrew"
elif [[ -x /opt/homebrew/bin/brew ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_REPOSITORY="/opt/homebrew"
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi
```

On Apple Silicon you DO need to add `/opt/homebrew/bin` to PATH (it's not in default `/etc/paths`).

### Synchronous plugin loads add ~500ms each

Without zinit's `wait` ice, each plugin blocks the prompt. With turbo mode, plugins load AFTER the first prompt appears.

**Fix:** Use `wait lucid` for everything except plugins that absolutely must be sync.
```zsh
zinit wait lucid depth=1 for \
  OMZP::git \
  OMZP::sudo \
  OMZP::aws \
  OMZP::kubectl \
  zsh-users/zsh-completions \
  Aloxaf/fzf-tab \
  zsh-users/zsh-autosuggestions \
  atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" zsh-users/zsh-syntax-highlighting
```

`atinit` on syntax-highlighting runs `zicompinit` (zinit's cached compinit) right before that plugin loads — collapses all completion-defining plugins into one compinit call.

### Slow third-party completion sources

Common offenders measured in real shells:
- Google Cloud SDK `completion.zsh.inc` — **2.3s**
- `entire completion zsh` — **1.9s**
- `bun _bun` — **0.7s**

**Fix:** Defer them via zinit `wait` using the null-plugin pattern.
```zsh
zinit wait lucid for \
  has'gcloud' id-as'gcloud-completion' \
    atinit"[[ -f $HOME/Downloads/google-cloud-sdk/completion.zsh.inc ]] && source $HOME/Downloads/google-cloud-sdk/completion.zsh.inc" \
    zdharma-continuum/null \
  has'bun' id-as'bun-completion' \
    atinit"[[ -s $HOME/.bun/_bun ]] && source $HOME/.bun/_bun" \
    zdharma-continuum/null \
  has'entire' id-as'entire-completion' \
    atinit'source <(entire completion zsh)' \
    zdharma-continuum/null
```

The actual commands (gcloud, bun, entire) work immediately because they're on PATH — only their tab-completion is briefly unavailable for ~1s after the shell opens.

### Cached compinit vs full compinit

Full `compinit` does a security check on every entry in fpath — slow with many plugins. Caching skips the check if `.zcompdump` is fresh.

**Pattern:** Use `ZINIT[COMPINIT_OPTS]=-C` before `zicompinit` (as in the turbo-mode block above). For non-zinit setups:
```zsh
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
```

## Correctness gotchas

### macOS ships BSD ls, not GNU

`ls --color` doesn't work. Use `ls -G`.

```zsh
alias ls='ls -G'
```

### LS_COLORS is needed for colored fzf-tab completions

Setting `ls -G` only affects `ls` output. For colored completion menus you need `LS_COLORS` set. macOS doesn't ship `dircolors`, but you can hardcode a portable string:

```zsh
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
```

### Case-insensitive completion

Off by default in zsh. One-liner:
```zsh
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
```

### Apple's `/etc/zshrc_Apple_Terminal` adds session-restore overhead

In Apple Terminal, every shell start sources `/etc/zshrc` which sources `/etc/zshrc_Apple_Terminal`, which sets up session save/restore (the `Saving session...completed.` line you see on exit). Adds ~1.5s per shell. Unavoidable inside Apple Terminal.

**Implication:** Realistic startup target in Apple Terminal is ~2-3s. In WezTerm/Ghostty/Alacritty, sub-second is achievable.

## Plugin / tap status gotchas

### `homebrew/command-not-found` tap is dead

Deprecated and removed. The `OMZP::command-not-found` snippet is unusable on macOS — the Debian handler it depends on doesn't exist. Just don't include the snippet.

### Powerlevel10k is in maintenance mode

Maintainer stepped away in 2024. It still works but isn't actively developed. **Starship** or **Oh My Posh** are the actively-maintained alternatives.

## WezTerm gotchas

### Subprocesses spawned by WezTerm get a minimal PATH

Default is `/usr/bin:/bin:/usr/sbin:/sbin` — no `/usr/local/bin`. So `viddy`, `lazygit`, `oh-my-posh`, etc. won't resolve in spawned panes (they DO work in your shell because the shell's PATH includes brew, but WezTerm's `command = { args = { 'viddy', ... } }` bypasses the shell).

**Fix:**
```lua
config.set_environment_variables = {
  PATH = '/usr/local/bin:/usr/local/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:' .. (os.getenv('PATH') or ''),
}
```

### Workspaces hide, don't close

When the user switches workspaces, the previous one's tabs become invisible (still alive). Users perceive this as "lost my terminal." Mitigations:
- Bind a workspace overview shortcut: `wezterm.action.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' }`
- Toast on workspace change so the user sees the transition

### Workspaces are global — multi-window + workspaces don't combine

WezTerm's "active workspace" is a global concept, not per-window. There's only ONE active workspace at a time across the whole WezTerm process. When you switch workspaces (via `mux.set_active_workspace` OR `wezterm.action.SwitchToWorkspace` — both end up doing the same thing globally), all GUI windows attached to other workspaces become hidden.

Practical implication: **don't try to use workspaces to keep multiple GUI windows independent.** The pattern "open a new window, switch its workspace to project X" looks reasonable but breaks: the new window vanishes (it was attached to the old workspace, which is now inactive) and the original window switches to project X instead.

**For a per-project layout, use TABS, not workspaces.** Tabs are window-local. Each project = one tab in the current window. Cmd-1 .. Cmd-9 switches tabs. Multi-window then works because each window's tabs are independent.

Project-switcher pattern using tabs:
```lua
{
  key = 'p',
  mods = 'CMD',
  action = wezterm.action_callback(function(window, pane)
    window:perform_action(
      wezterm.action.InputSelector {
        title = 'Switch to project',
        fuzzy = true,
        choices = project_choices(),
        action = wezterm.action_callback(function(win, p, id, label)
          if not id then return end
          local mux_win = win:mux_window()
          -- Re-activate existing tab if there is one
          for _, tab in ipairs(mux_win:tabs()) do
            if tab:get_title() == label then tab:activate(); return end
          end
          -- Otherwise create a new tab with the layout
          local tab, main_pane, _ = mux_win:spawn_tab { cwd = id }
          tab:set_title(label)
          main_pane:split {
            direction = 'Right', size = 0.25, cwd = id,
            args = { 'viddy', '--interval', '2', '--differences', 'git', 'status', '-s' },
          }
        end),
      },
      pane
    )
  end),
},
```

If you DO use workspaces (e.g. for ad-hoc isolation that the user controls manually), document the limitation clearly and stick to single-window workflows. Don't ship a project switcher that uses workspaces.

### Plugin order in zsh

`zsh-syntax-highlighting` must load **last**. `fzf-tab` must load **after** completions and **before** syntax-highlighting. Get this wrong and silent breakage ensues.

## Profiling

If startup is over 5s, profile:
```sh
zsh -i -c 'zmodload zsh/zprof; source ~/.zshrc; zprof' | head -30
```

`zprof` shows Lua-style function timings but **misses time spent inside `eval "$(...)"` calls** (the eval'd code isn't a "function"). Bisect those manually:
```sh
for cmd in 'brew shellenv' 'starship init zsh' 'fnm env --use-on-cd --shell zsh' 'fzf --zsh' 'gcloud completion' 'bun _bun' 'entire completion zsh'; do
  /bin/sh -c "TIMEFORMAT=\"%R s  $cmd\"; time $cmd >/dev/null 2>&1" 2>&1 | tail -1
done
```

Always measure from `/bin/sh` (not from inside zsh), to avoid wrapper overhead. Run 3-5 times and take the lower runs (first run pays cache miss).
