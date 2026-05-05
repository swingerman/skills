-- ~/.wezterm.lua — base config bundled with the zenify-my-terminal skill.
-- Includes: font/theme/padding, sub-process PATH (CRITICAL), tab/pane keys,
-- bottom status bar, project switcher (TAB-based — NOT workspace-based),
-- viddy git-status pane, lazygit pane, kill-workspace shortcut.
--
-- See wezterm-extras.md in the skill for per-feature details and what's safe
-- to drop if the user opted out of any extras.

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Tweakable knobs ------------------------------------------------------------
local FONT_FAMILY  = 'JetBrainsMono Nerd Font'
local FONT_SIZE    = 14
local COLOR_SCHEME = 'Catppuccin Macchiato'
-----------------------------------------------------------------------------

config.font         = wezterm.font(FONT_FAMILY)
config.font_size    = FONT_SIZE
config.color_scheme = COLOR_SCHEME

-- CRITICAL: spawned subprocesses inherit a richer PATH so brew-installed tools
-- (viddy, lazygit, oh-my-posh, fzf, zoxide, etc.) resolve. WezTerm's default
-- only includes /usr/bin:/bin:/usr/sbin:/sbin.
config.set_environment_variables = {
  PATH = '/usr/local/bin:/usr/local/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:' .. (os.getenv('PATH') or ''),
}

config.window_padding = {
  left = 10, right = 10, top = 10, bottom = 10,
}

config.tab_bar_at_bottom            = true
config.use_fancy_tab_bar            = false
config.hide_tab_bar_if_only_one_tab = false   -- status bar requires tab bar visible
config.window_decorations           = 'TITLE | RESIZE'

-- Make Option behave as Alt (so Esc-prefixed shortcuts work in zsh)
config.send_composed_key_when_left_alt_is_pressed  = false
config.send_composed_key_when_right_alt_is_pressed = true

-- Kitty keyboard protocol: lets WezTerm distinguish Shift+Enter from plain
-- Enter (and other modified keys). Required for multi-line input in Claude
-- Code — without this, Shift+Enter and Alt+Enter both submit the prompt.
-- Open a NEW WINDOW (not tab) after editing for the negotiation to take
-- effect. Fallbacks that always work: Ctrl-J (literal LF), or trailing
-- backslash + Enter for line continuation.
config.enable_kitty_keyboard = true

-- Bottom status bar:
--   left  = active tab title (project) | git branch | worktree (if linked)
--   right = current working directory (home shortened to ~)

-- Git info cache (5s TTL) so we don't shell out on every status tick.
local git_cache = {}

local function git_info(cwd)
  if not cwd or cwd == '' then return nil, nil end
  local now = os.time()
  local entry = git_cache[cwd]
  if entry and (now - entry.t) < 5 then
    return entry.branch, entry.worktree
  end

  local ok, stdout = wezterm.run_child_process({ 'git', '-C', cwd, 'rev-parse', '--abbrev-ref', 'HEAD' })
  if not ok then
    git_cache[cwd] = { t = now, branch = nil, worktree = nil }
    return nil, nil
  end
  local branch = (stdout or ''):gsub('%s+', '')
  if branch == 'HEAD' then
    local ok2, sha = wezterm.run_child_process({ 'git', '-C', cwd, 'rev-parse', '--short', 'HEAD' })
    if ok2 then branch = '@' .. (sha or ''):gsub('%s+', '') end
  end

  local worktree = nil
  local _, gitdir = wezterm.run_child_process({ 'git', '-C', cwd, 'rev-parse', '--git-dir' })
  local _, common = wezterm.run_child_process({ 'git', '-C', cwd, 'rev-parse', '--git-common-dir' })
  if gitdir and common and gitdir ~= common then
    local _, top = wezterm.run_child_process({ 'git', '-C', cwd, 'rev-parse', '--show-toplevel' })
    if top then
      top = top:gsub('%s+', '')
      worktree = top:match('([^/]+)$')
    end
  end

  git_cache[cwd] = { t = now, branch = branch, worktree = worktree }
  return branch, worktree
end

wezterm.on('update-status', function(window, pane)
  local cwd_uri = pane:get_current_working_dir()
  local raw_cwd = cwd_uri and (cwd_uri.file_path or '') or ''
  if raw_cwd:sub(-1) == '/' and #raw_cwd > 1 then raw_cwd = raw_cwd:sub(1, -2) end

  local cwd = raw_cwd
  local home = os.getenv('HOME') or ''
  if home ~= '' and cwd:sub(1, #home) == home then
    cwd = '~' .. cwd:sub(#home + 1)
  end

  local branch, worktree = nil, nil
  if raw_cwd ~= '' then branch, worktree = git_info(raw_cwd) end

  local active_tab = window:active_tab()
  local label = active_tab and active_tab:get_title() or ''
  if label == '' then label = window:active_workspace() end

  local left = {
    { Foreground = { AnsiColor = 'Blue' } },
    { Text = '  ' .. label },
  }
  if branch then
    table.insert(left, { Foreground = { AnsiColor = 'Silver' } })
    table.insert(left, { Text = '  │  ' })
    table.insert(left, { Foreground = { AnsiColor = 'Purple' } })
    table.insert(left, { Text = ' ' .. branch })
  end
  if worktree then
    table.insert(left, { Foreground = { AnsiColor = 'Silver' } })
    table.insert(left, { Text = '  ' })
    table.insert(left, { Foreground = { AnsiColor = 'Olive' } })
    table.insert(left, { Text = ' ' .. worktree })
  end
  table.insert(left, { Text = '  ' })
  window:set_left_status(wezterm.format(left))

  window:set_right_status(wezterm.format {
    { Foreground = { AnsiColor = 'Fuchsia' } },
    { Text = '  ' .. cwd .. '  ' },
  })
end)

-- Project switcher data source: subdirs of ~/projects.
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

config.keys = {
  -- Tabs
  { key = 't', mods = 'CMD',       action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CMD',       action = wezterm.action.CloseCurrentTab { confirm = true } },
  { key = 'k', mods = 'CMD',       action = wezterm.action.ClearScrollback 'ScrollbackAndViewport' },

  -- Pane splits (iTerm2-style)
  { key = 'd', mods = 'CMD',       action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'CMD|SHIFT', action = wezterm.action.SplitVertical   { domain = 'CurrentPaneDomain' } },

  -- Pane focus (Cmd-Opt-Arrow)
  { key = 'LeftArrow',  mods = 'CMD|OPT', action = wezterm.action.ActivatePaneDirection 'Left'  },
  { key = 'RightArrow', mods = 'CMD|OPT', action = wezterm.action.ActivatePaneDirection 'Right' },
  { key = 'UpArrow',    mods = 'CMD|OPT', action = wezterm.action.ActivatePaneDirection 'Up'    },
  { key = 'DownArrow',  mods = 'CMD|OPT', action = wezterm.action.ActivatePaneDirection 'Down'  },

  -- Close current pane (Cmd-Shift-W; Cmd-W still closes the whole tab)
  { key = 'w', mods = 'CMD|SHIFT', action = wezterm.action.CloseCurrentPane { confirm = true } },

  -- Live git-status side pane (viddy)
  {
    key = 'g',
    mods = 'CMD',
    action = wezterm.action.SplitPane {
      direction = 'Right',
      size      = { Percent = 25 },
      command   = { args = { 'viddy', '--interval', '2', '--differences', 'git', 'status', '-s' } },
    },
  },

  -- Lazygit (full diff viewer + stage/commit/branch)
  {
    key = 'g',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SplitPane {
      direction = 'Down',
      size      = { Percent = 50 },
      command   = { args = { 'lazygit' } },
    },
  },

  -- Project switcher: each project = one TAB (not workspace) with shell + viddy.
  -- Tabs are window-local, so this works correctly across multiple windows.
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
            for _, tab in ipairs(mux_win:tabs()) do
              if tab:get_title() == label then
                tab:activate()
                return
              end
            end
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

  -- Workspace navigation (kept for ad-hoc isolation; not used by project switcher)
  { key = ']', mods = 'CMD|SHIFT', action = wezterm.action.SwitchWorkspaceRelative(  1) },
  { key = '[', mods = 'CMD|SHIFT', action = wezterm.action.SwitchWorkspaceRelative( -1) },
  { key = 'o', mods = 'CMD|SHIFT', action = wezterm.action.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },

  -- Kill the entire active workspace at once
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
}

return config
