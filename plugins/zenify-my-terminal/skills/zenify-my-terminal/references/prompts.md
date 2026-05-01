# Prompts — Starship vs Oh My Posh

Both render the prompt by hooking into zsh's `precmd`. Both are Go binaries, both actively maintained, both work with any modern terminal. The trade-off:

| | Starship | Oh My Posh |
|---|---|---|
| Themes | One config (TOML); presets via `starship preset` | 125 bundled themes (JSON), pick by name |
| Customization | Edit a single `~/.config/starship.toml` | Pick a theme, optionally copy + edit JSON |
| P10K port available | No | Yes — 4 themes (`powerlevel10k_classic / lean / modern / rainbow`) |
| Startup cost | ~330ms | ~1s |
| Interactive setup wizard | No | No (P10K had this; neither successor does) |
| Best for | Users who want one clean look and don't tweak much | Users who want lots of pre-built themes to browse and switch between |

## Starship

**Install:** `brew install starship`

**Init line in `.zshrc`:** `eval "$(starship init zsh)"`

**Config:** `~/.config/starship.toml`

**Bundled preset in this skill:** `assets/starship-pure.toml` (pure-style, two-line, no clock).

**Switching presets:** browse with `starship preset --list`, apply with e.g. `starship preset gruvbox-rainbow > ~/.config/starship.toml`.

## Oh My Posh

**Install:** `brew install oh-my-posh`

**Init line in `.zshrc`:** `eval "$(oh-my-posh init zsh --config <theme-path>)"`

**Themes ship with the brew install:** `/usr/local/opt/oh-my-posh/themes/` (Intel) or `/opt/homebrew/opt/oh-my-posh/themes/` (Apple Silicon). 125 themes, each a `.omp.json` file.

**Browse themes:**

- Visual gallery: https://ohmyposh.dev/docs/themes
- Local list: `ls $HOMEBREW_PREFIX/opt/oh-my-posh/themes/`
- **Live preview in the terminal**: run the bundled script `scripts/preview-themes.sh` — it loops over a curated representative set (or all 125 with `--all`, or just the P10K ports with `--p10k`) and renders each prompt to stdout. The user sees the actual look, not a screenshot.

```sh
# Curated set (~15 themes — pure, P10K ports, popular ones)
bash scripts/preview-themes.sh

# All bundled themes
bash scripts/preview-themes.sh --all

# Just the P10K-style ones
bash scripts/preview-themes.sh --p10k

# Specific themes by name
bash scripts/preview-themes.sh atomic montys catppuccin
```

**Powerlevel10k ports (for users coming from P10K):**

| OMP theme | P10K equivalent |
|---|---|
| `powerlevel10k_lean.omp.json` | Lean style |
| `powerlevel10k_classic.omp.json` | Classic style |
| `powerlevel10k_modern.omp.json` | Modern style |
| `powerlevel10k_rainbow.omp.json` | Rainbow style |

These give the exact P10K aesthetic the YouTube tutorials show, without the maintenance-mode P10K codebase.

**Switching themes:** edit the `--config` path in `~/.zshrc` and reload (open a new shell). To preview one without committing:
```sh
oh-my-posh print primary --config $HOMEBREW_PREFIX/opt/oh-my-posh/themes/<name>.omp.json
```

**Custom JSON (your own theme):** copy any built-in to your config dir and edit:
```sh
cp $HOMEBREW_PREFIX/opt/oh-my-posh/themes/pure.omp.json ~/.config/oh-my-posh.json
# Edit ~/.config/oh-my-posh.json — segments, colors, leading/trailing chars, what shows on left/right
```
Then point `.zshrc` at the copy:
```sh
eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh.json)"
```

Schema reference: https://ohmyposh.dev/docs/configuration/overview

**Common tweaks:**

- **Drop the right-side time segment** (avoid clock-watching): in your custom JSON, find the block with `"type": "time"` and either delete it or remove its enclosing block from the `blocks` array.
- **Two-line prompt**: ensure there's a block with `"type": "prompt"` and `"newline": true`.
- **Transient prompt** (collapse old prompts to a minimal symbol when you submit a new command): add a top-level `"transient_prompt"` block — see https://ohmyposh.dev/docs/configuration/transient.
