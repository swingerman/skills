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

### `source <(cmd)` is fragile inside zinit deferred loads — use `eval "$(cmd)"`

In a synchronous `~/.zshrc`, `source <(somecommand)` works fine. But inside zinit's deferred (`wait lucid`) blocks, multiple plugins fire close together off the scheduler — and process-substitution fds (`/dev/fd/N`) can be closed mid-read when another deferred hook runs. The shell ends up parsing partial output and you get cryptic errors like `/dev/fd/18:214: number expected` and `/dev/fd/18:215: command not found: Run`. The errors are intermittent — they look like flaky shell startup that "sometimes" fails on a new window.

**Fix:** use `eval "$(somecommand)"` instead. `eval` captures the command's output as a fully-formed string before zsh parses it, so nothing depends on a fd staying open.

Wrong:
```zsh
zinit wait lucid for \
  has'entire' id-as'entire-completion' \
    atinit'source <(entire completion zsh)' \
    zdharma-continuum/null
```

Right:
```zsh
zinit wait lucid for \
  has'entire' id-as'entire-completion' \
    atinit'eval "$(entire completion zsh)"' \
    zdharma-continuum/null
```

This applies to anything sourced via process substitution in deferred contexts: `entire`, custom CLIs that ship completion via `<cmd> completion zsh`, etc. The synchronous `source <(fzf --zsh)` in `~/.zshrc` proper is also safer as `eval "$(fzf --zsh)"` since it removes one possible source of intermittent failure.

## Plugin / tap status gotchas

### `homebrew/command-not-found` tap is dead

Deprecated and removed. The `OMZP::command-not-found` snippet is unusable on macOS — the Debian handler it depends on doesn't exist. Just don't include the snippet.

### Powerlevel10k is in maintenance mode

Maintainer stepped away in 2024. It still works but isn't actively developed. **Starship** or **Oh My Posh** are the actively-maintained alternatives.

## Terminal-specific gotchas

Each terminal has its own quirks (sub-process PATH, font fallback, workspace semantics). See the per-terminal references in [`terminals/`](terminals/) for setup details and known-broken patterns.

### Claude Code multi-line input (Shift+Enter / Alt+Enter)

By default many terminals send the same byte sequence (`\r`) for plain Enter, Shift+Enter, and Alt+Enter — so Claude Code can't tell them apart and every variant submits the prompt. The fix depends on the terminal:

- **WezTerm**: `config.enable_kitty_keyboard = true` in `~/.wezterm.lua`, then open a NEW window.
- **Kitty**: enabled by default (Kitty owns the protocol).
- **Ghostty / cmux**: support the protocol natively; no config needed.
- **Alacritty / VS Code / Cursor / Zed**: run `/terminal-setup` inside Claude Code.
- **iTerm2**: configure manually — Settings → Profiles → Keys → add Shift+Enter sending `\n`, OR run `/terminal-setup`.
- **Apple Terminal**: no fix — use the always-available fallbacks below.

**Always-available fallbacks** (no config needed, work everywhere): **Ctrl-J** sends a literal LF, and a trailing **`\` + Enter** uses Claude Code's line-continuation parser.

Source: [Claude Code Terminal Configuration](https://code.claude.com/docs/en/terminal-config).

## Other shell gotchas

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
