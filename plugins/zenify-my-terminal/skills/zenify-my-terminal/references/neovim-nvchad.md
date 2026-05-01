# Neovim + NvChad (opt-in)

Modern Neovim setup using **NvChad** — a community-maintained Lua config providing file tree, fuzzy finder, LSP, treesitter, status line, and a polished theme out of the box. The user invokes it as `vim` (aliased), edits files, and gets an IDE-like experience without writing Lua themselves.

This is **opt-in** in the skill — not part of fast-track. It's invasive (clones a full config, runs plugin install on first launch, takes ~30s), and many users have an existing nvim config they don't want to lose. Only install if explicitly requested.

## When to suggest it

- User mentioned wanting a "better vim" or modern editor
- User asked about Neovim, NvChad, LazyVim, or similar
- User said something like "I'm tired of using vim, what's modern"

Don't push it during the standard zenify flow.

## What gets installed

- `neovim` (Neovim 0.10+, required by NvChad)
- `ripgrep` and `fd` (for the fuzzy finder — telescope.nvim)
- `~/.config/nvim` populated with the [NvChad starter](https://github.com/NvChad/starter)
- Aliases in `.zshrc`: `vim` → `nvim`, `vi` → `nvim`
- `EDITOR` and `VISUAL` env vars set to `nvim`

## Pre-install: back up existing nvim config

If the user has an existing `~/.config/nvim`, **back it up first** — overwriting it loses their config:

```sh
if [[ -d ~/.config/nvim ]]; then
  mv ~/.config/nvim ~/.config/nvim.bak.$(date +%Y%m%d)
  echo "Existing config backed up."
fi
```

Same for plugin/cache state (NvChad uses lazy.nvim which has its own dirs):

```sh
[[ -d ~/.local/share/nvim ]] && mv ~/.local/share/nvim ~/.local/share/nvim.bak.$(date +%Y%m%d)
[[ -d ~/.local/state/nvim ]] && mv ~/.local/state/nvim ~/.local/state/nvim.bak.$(date +%Y%m%d)
[[ -d ~/.cache/nvim       ]] && mv ~/.cache/nvim       ~/.cache/nvim.bak.$(date +%Y%m%d)
```

Confirm with the user before moving any of these — explain what's being backed up.

## Install

```sh
brew install neovim ripgrep fd
git clone https://github.com/NvChad/starter ~/.config/nvim --depth 1
```

Then add to `~/.zshrc` (in the aliases section):

```zsh
# Neovim
alias vim='nvim'
alias vi='nvim'
export EDITOR='nvim'
export VISUAL='nvim'
```

## First launch

```sh
nvim
```

On first launch, NvChad's lazy.nvim plugin manager auto-installs all plugins (~30s). The user sees a `Lazy` status window. When it finishes, press `q` to close. Subsequent launches are fast.

After plugin install, also run `:MasonInstallAll` inside nvim to install LSP servers / formatters / linters Mason knows about — adds another ~30s.

## Verify

```sh
nvim --version | head -1     # Should show NVIM v0.10+
which nvim                   # /usr/local/bin/nvim or /opt/homebrew/bin/nvim
zsh -i -c 'alias vim'        # Should print: vim='nvim'
```

## Most important NvChad keybindings

NvChad uses `Space` as the leader key.

| Key | Action |
|---|---|
| `Space + ff` | Find files (telescope) |
| `Space + fw` | Find word in project (live grep) |
| `Space + fb` | Find open buffer |
| `Space + e` | Toggle file tree (NvimTree) |
| `Space + th` | Theme picker (browse themes interactively) |
| `Space + ch` | Cheat sheet (show all keybindings) |
| `Tab` / `Shift-Tab` | Cycle through open buffers |
| `Space + x` | Close current buffer |
| `Space + n` | Toggle line numbers |
| `gd` | Go to definition (LSP) |
| `gr` | Show references (LSP) |
| `K` | Hover documentation |
| `Space + ca` | Code action |
| `Space + ra` | Rename symbol |
| `:Mason` | Open LSP/formatter/linter installer |

## Customizing NvChad

The starter is a normal nvim config — edit files in `~/.config/nvim/` directly:

- `~/.config/nvim/init.lua` — entry point
- `~/.config/nvim/lua/configs/` — plugin configs
- `~/.config/nvim/lua/plugins/init.lua` — add new plugins
- `~/.config/nvim/lua/chadrc.lua` — NvChad-specific settings (theme, ui)

Browse themes interactively with `Space + th` — applies immediately.

## Alternatives the skill could offer

NvChad isn't the only modern Neovim distribution. If the user has preferences:

- **LazyVim** (`https://www.lazyvim.org`) — similarly opinionated, slightly more "batteries included"
- **AstroNvim** (`https://astronvim.com`) — another popular distro
- **kickstart.nvim** (`https://github.com/nvim-lua/kickstart.nvim`) — minimal "build your own" template

Setup pattern is the same: backup existing config, clone the new one, launch nvim, wait for plugin install. The skill defaults to NvChad but can substitute easily.

## Rollback

```sh
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
mv ~/.config/nvim.bak.YYYYMMDD ~/.config/nvim   # if there was a backup
# Remove the alias + EDITOR lines from ~/.zshrc
```
