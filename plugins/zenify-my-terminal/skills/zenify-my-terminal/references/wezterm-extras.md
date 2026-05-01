# WezTerm Extras — Optional Power-User Features

Each is opt-in. Add to `~/.wezterm.lua` only if the user asks. None depend on each other (mostly).

## 1. Sub-process PATH (REQUIRED if using any extra below)

WezTerm spawns processes with a minimal PATH. Without this, `viddy`, `lazygit`, `oh-my-posh` etc. won't resolve when launched from a keybinding.

```lua
config.set_environment_variables = {
  PATH = '/usr/local/bin:/usr/local/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:' .. (os.getenv('PATH') or ''),
}
```

## 2. Pane splits + navigation

iTerm2-style.

```lua
{ key = 'd', mods = 'CMD',       action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
{ key = 'd', mods = 'CMD|SHIFT', action = wezterm.action.SplitVertical   { domain = 'CurrentPaneDomain' } },

{ key = 'LeftArrow',  mods = 'CMD|OPT', action = wezterm.action.ActivatePaneDirection 'Left'  },
{ key = 'RightArrow', mods = 'CMD|OPT', action = wezterm.action.ActivatePaneDirection 'Right' },
{ key = 'UpArrow',    mods = 'CMD|OPT', action = wezterm.action.ActivatePaneDirection 'Up'    },
{ key = 'DownArrow',  mods = 'CMD|OPT', action = wezterm.action.ActivatePaneDirection 'Down'  },

{ key = 'w', mods = 'CMD|SHIFT', action = wezterm.action.CloseCurrentPane { confirm = true } },
```

## 3. Bottom status bar (workspace + cwd)

Workspace name on the left, cwd (with `~` shortened) on the right.

```lua
config.tab_bar_at_bottom            = true
config.use_fancy_tab_bar            = false
config.hide_tab_bar_if_only_one_tab = false   -- status bar requires the tab bar to be visible

wezterm.on('update-status', function(window, pane)
  local cwd_uri = pane:get_current_working_dir()
  local cwd = ''
  if cwd_uri then
    cwd = cwd_uri.file_path or ''
    if cwd:sub(-1) == '/' and #cwd > 1 then cwd = cwd:sub(1, -2) end
    local home = os.getenv('HOME') or ''
    if home ~= '' and cwd:sub(1, #home) == home then
      cwd = '~' .. cwd:sub(#home + 1)
    end
  end
  window:set_left_status(wezterm.format {
    { Foreground = { AnsiColor = 'Blue' } },
    { Text = '  ' .. window:active_workspace() .. '  ' },
  })
  window:set_right_status(wezterm.format {
    { Foreground = { AnsiColor = 'Fuchsia' } },
    { Text = '  ' .. cwd .. '  ' },
  })
end)
```

## 4. Live git-status side pane (viddy)

Requires `brew install viddy`. Splits a 25%-width right pane with auto-refreshing `git status -s`.

```lua
{
  key = 'g',
  mods = 'CMD',
  action = wezterm.action.SplitPane {
    direction = 'Right',
    size      = { Percent = 25 },
    command   = { args = { 'viddy', '--interval', '2', '--differences', 'git', 'status', '-s' } },
  },
},
```

## 5. Lazygit pane (full diff viewer)

Requires `brew install lazygit`. Splits 50% below; user closes with `q`.

```lua
{
  key = 'g',
  mods = 'CMD|SHIFT',
  action = wezterm.action.SplitPane {
    direction = 'Down',
    size      = { Percent = 50 },
    command   = { args = { 'lazygit' } },
  },
},
```

## 6. Project switcher (Cmd-P) — TAB-BASED

Fuzzy picker over `~/projects/*` subdirs. Each project = one TAB in the current window with a 75/25 layout (main shell + viddy git status). Cmd-1..9 switches tabs. Selecting an already-open project re-activates its tab.

**This deliberately avoids workspaces.** Workspaces are global in WezTerm — multi-window + workspaces breaks (see [gotchas.md](gotchas.md#workspaces-are-global--multi-window--workspaces-dont-combine)). Tabs are window-local and play nicely with multiple windows.

```lua
local function project_choices()
  local choices = {}
  local ok, entries = pcall(wezterm.read_dir, wezterm.home_dir .. '/projects')
  if not ok or not entries then return choices end
  for _, dir in ipairs(entries) do
    local name = dir:match('([^/]+)$')
    if name and not name:match('^%.') then
      table.insert(choices, { id = dir, label = name })
    end
  end
  table.sort(choices, function(a, b) return a.label < b.label end)
  return choices
end

-- Inside config.keys:
{
  key = 'p',
  mods = 'CMD',
  action = wezterm.action_callback(function(window, pane)
    window:perform_action(
      wezterm.action.InputSelector {
        title   = 'Switch to project',
        fuzzy   = true,
        choices = project_choices(),
        action  = wezterm.action_callback(function(win, p, id, label)
          if not id then return end
          local mux_win = win:mux_window()

          -- Re-activate an existing tab if the project is already open here
          for _, tab in ipairs(mux_win:tabs()) do
            if tab:get_title() == label then
              tab:activate()
              return
            end
          end

          -- Otherwise spawn a new tab with the two-pane layout
          local tab, main_pane, _ = mux_win:spawn_tab { cwd = id }
          tab:set_title(label)
          main_pane:split {
            direction = 'Right',
            size      = 0.25,
            cwd       = id,
            args      = { 'viddy', '--interval', '2', '--differences', 'git', 'status', '-s' },
          }
        end),
      },
      pane
    )
  end),
},
```

If the user doesn't have viddy installed (or didn't opt in), drop the `:split { ... }` block — they'll just get a single shell pane.

If the user explicitly wants the bottom-bar segment to show the project name, update the status bar handler to use the active tab's title:
```lua
local active_tab = window:active_tab()
local label = active_tab and active_tab:get_title() or window:active_workspace()
window:set_left_status(wezterm.format {
  { Foreground = { AnsiColor = 'Blue' } },
  { Text = '  ' .. label .. '  ' },
})
```

## 7. Workspace navigation

- `Cmd-Shift-]` / `Cmd-Shift-[` — cycle workspaces
- `Cmd-Shift-O` — fuzzy launcher over open workspaces

```lua
{ key = ']', mods = 'CMD|SHIFT', action = wezterm.action.SwitchWorkspaceRelative(  1) },
{ key = '[', mods = 'CMD|SHIFT', action = wezterm.action.SwitchWorkspaceRelative( -1) },
{ key = 'o', mods = 'CMD|SHIFT', action = wezterm.action.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
```

## 8. Workspace-switch toast

3-second on-screen notification when the active workspace changes — helps users not "lose track" of hidden workspaces.

```lua
local last_seen_workspace = nil
wezterm.on('update-status', function(window, _)
  local current = window:active_workspace()
  if last_seen_workspace ~= nil and current ~= last_seen_workspace then
    window:toast_notification(
      'WezTerm',
      'Workspace: ' .. current .. '   (Cmd-Shift-[ / Cmd-Shift-O to navigate back)',
      nil, 3000
    )
  end
  last_seen_workspace = current
end)
```

If you also added the bottom status bar (extra #3), this is a SECOND `update-status` handler — WezTerm runs both. Don't merge them by accident or one will silently disappear.

## 9. Kill workspace (Cmd-Shift-Q)

Closes every tab in the active workspace at once. Switches to another workspace first to avoid landing nowhere.

```lua
{
  key = 'q',
  mods = 'CMD|SHIFT',
  action = wezterm.action_callback(function(window, _)
    local mux    = wezterm.mux
    local target = window:active_workspace()

    local landing = nil
    for _, ws in ipairs(mux.get_workspace_names()) do
      if ws ~= target then landing = ws; break end
    end
    if landing then mux.set_active_workspace(landing) end

    for _, mux_win in ipairs(mux.all_windows()) do
      if mux_win:get_workspace() == target then
        local gui_win = mux_win:gui_window()
        if gui_win then
          for _ = 1, #mux_win:tabs() do
            local active_tab = mux_win:active_tab()
            if active_tab then
              gui_win:perform_action(
                wezterm.action.CloseCurrentTab { confirm = false },
                active_tab:active_pane()
              )
            end
          end
        end
      end
    end
  end),
},
```

Note: this DOES use `mux.set_active_workspace` because we want to switch globally before nuking — the multi-window bug doesn't apply here since we're explicitly killing the workspace anyway.
