local wezterm = require "wezterm"
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find("windows") ~= nil

if is_windows then
  config.default_prog = { "pwsh.exe", "-NoLogo" }
  -- Windows 11 blurs whatever sits behind the window. The background colour below
  -- still tints it, so the purple survives instead of turning into plain grey glass.
  config.win32_system_backdrop = "Acrylic"
end

config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 12

-- GPU rendering. WebGpu is the modern backend and keeps scrolling through long
-- output smooth; max_fps only matters on displays above 60Hz.
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.max_fps = 120

-- Low enough for the acrylic blur to read, high enough to keep the background dark
config.window_background_opacity = 0.7

-- Dim panes that don't have focus, so a split is readable without hunting the cursor
config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.65,
}

config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

config.default_cursor_style = "BlinkingBar"
config.scrollback_lines = 50000
config.enable_scroll_bar = true

-- Custom purple color scheme (matches the oh-my-posh prompt palette)
config.colors = {
  foreground = "#E0D6F5",
  background = "#05030A",
  cursor_bg = "#C792EA",
  cursor_border = "#C792EA",
  cursor_fg = "#1A1025",
  selection_bg = "#4B2E83",
  selection_fg = "#E0D6F5",
  scrollbar_thumb = "#5C3D7A",
  split = "#4B2E83",

  ansi = {
    "#241733", -- black
    "#E0A6E8", -- red
    "#7FDBAA", -- green
    "#F5D76E", -- yellow
    "#7C7CE0", -- blue
    "#C792EA", -- magenta
    "#63D9E0", -- cyan
    "#E0D6F5", -- white
  },
  brights = {
    "#4B3B5C", -- bright black
    "#F5B8E8", -- bright red
    "#9CFFC7", -- bright green
    "#FFEB99", -- bright yellow
    "#A6A6FF", -- bright blue
    "#E0A6E8", -- bright magenta
    "#9CF0F5", -- bright cyan
    "#FFFFFF", -- bright white
  },
}

-- No Windows title bar: the minimize/maximize/close buttons are drawn inside the
-- tab bar instead, which then has to stay visible even with a single tab.
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.integrated_title_button_style = "Windows"
config.integrated_title_button_alignment = "Right"
config.integrated_title_button_color = "Auto"
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.tab_max_width = 40
config.show_new_tab_button_in_tab_bar = true

-- Tab bar colors (matches the purple color scheme above)
config.colors.tab_bar = {
  background = "#05030A",
  active_tab = {
    bg_color = "#4B2E83",
    fg_color = "#F5EBFF",
    intensity = "Bold",
  },
  inactive_tab = {
    bg_color = "#05030A",
    fg_color = "#8A6FA8",
  },
  inactive_tab_hover = {
    bg_color = "#2E1D47",
    fg_color = "#C792EA",
    italic = true,
  },
  new_tab = {
    bg_color = "#05030A",
    fg_color = "#8A6FA8",
  },
  new_tab_hover = {
    bg_color = "#2E1D47",
    fg_color = "#C792EA",
  },
}

-- Leader key (tmux-style prefix): Ctrl+A, then release and press the next key within 1s
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

config.initial_cols = 110
config.initial_rows = 30

-- Session persistence: tabs and panes live in a background mux server instead of the
-- GUI window, so closing the window (or a crash) leaves the running processes alone
-- and reopening reattaches to them. `wezterm start --no-auto-connect` gets a plain
-- window back if the server ever misbehaves.
config.unix_domains = { { name = "unix" } }
config.default_gui_startup_args = { "connect", "unix" }

-- Preserve long lines when copying (don't insert newlines at wrapping points)
config.canonicalize_pasted_newlines = "None"

config.mouse_bindings = {
  -- Ctrl+Click to open links
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "CTRL",
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
  -- Restore default: click selects text
  {
    event = { Down = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = wezterm.action.SelectTextAtMouseCursor "Cell",
  },
  {
    event = { Drag = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = wezterm.action.ExtendSelectionToMouseCursor "Cell",
  },
  -- Double-click selects word
  {
    event = { Down = { streak = 2, button = "Left" } },
    mods = "NONE",
    action = wezterm.action.SelectTextAtMouseCursor "Word",
  },
  -- Triple-click selects line
  {
    event = { Down = { streak = 3, button = "Left" } },
    mods = "NONE",
    action = wezterm.action.SelectTextAtMouseCursor "Line",
  },
  -- Right-click paste
  {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = wezterm.action.PasteFrom "Clipboard",
  },
}

-- Tab bar palette (shared by format-tab-title and update-right-status)
local BAR_BG      = "#05030A"
local ACTIVE_BG   = "#4B2E83"
local ACTIVE_FG   = "#F5EBFF"
local INACTIVE_BG = "#1A1025"
local INACTIVE_FG = "#8A6FA8"
local HOVER_BG    = "#2E1D47"
local HOVER_FG    = "#C792EA"
local ACCENT      = "#C792EA"
local DIM         = "#7A5C9E"

-- Flat rectangular blocks: one cell of bar background before every block, one cell
-- of padding inside each edge. No powerline caps, everything squared off.
local GAP = { { Background = { Color = BAR_BG } }, { Foreground = { Color = BAR_BG } }, { Text = " " } }

local ICON = {
  bell  = "\u{f0f3}",
  plus  = "\u{f067}",
  space = "\u{f009}", -- workspace

  -- Window buttons (codicons, same set VS Code draws in its title bar)
  minimize = "\u{eaba}",
  maximize = "\u{eab9}",
  close    = "\u{ea76}",
}

local BELL_FG = "#F5D76E"

-- Window buttons: the "Windows" style draws vector glyphs, so override each slot with
-- our own icon. Hover and non-hover must stay the same printable width (3 cells) --
-- WezTerm sizes the hit region from the hover string.
local CLOSE_HOVER_BG = "#B23A5B"

local function title_button(glyph, fg, bg)
  return wezterm.format {
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = " " .. glyph .. " " },
  }
end

-- "+" button as another flat block: same leading gap and inner padding as the tabs
config.tab_bar_style = {
  new_tab = wezterm.format {
    { Background = { Color = BAR_BG } }, { Text = " " },
    { Foreground = { Color = DIM } }, { Text = " " .. ICON.plus .. " " },
  },
  new_tab_hover = wezterm.format {
    { Background = { Color = BAR_BG } }, { Text = " " },
    { Background = { Color = HOVER_BG } }, { Foreground = { Color = HOVER_FG } },
    { Text = " " .. ICON.plus .. " " },
  },

  window_hide           = title_button(ICON.minimize, DIM, BAR_BG),
  window_hide_hover     = title_button(ICON.minimize, HOVER_FG, HOVER_BG),
  window_maximize       = title_button(ICON.maximize, DIM, BAR_BG),
  window_maximize_hover = title_button(ICON.maximize, HOVER_FG, HOVER_BG),
  window_close          = title_button(ICON.close, DIM, BAR_BG),
  window_close_hover    = title_button(ICON.close, "#FFFFFF", CLOSE_HOVER_BG),
}

-- Right status: the workspace name, and only when it isn't the unnamed "default" one,
-- so the bar stays empty in the common case.
wezterm.on("update-right-status", function(window)
  local workspace = window:active_workspace()
  if workspace == "default" then
    window:set_right_status("")
    return
  end

  local items = {}
  for _, item in ipairs(GAP) do
    table.insert(items, item)
  end
  for _, item in ipairs {
    { Background = { Color = INACTIVE_BG } },
    { Foreground = { Color = ACCENT } },
    { Text = " " .. ICON.space .. " " },
    { Foreground = { Color = ACTIVE_FG } },
    { Text = workspace .. " " },
    { Background = { Color = BAR_BG } },
    { Text = " " },
  } do
    table.insert(items, item)
  end

  window:set_right_status(wezterm.format(items))
end)

local function process_name(pane)
  local proc = pane.foreground_process_name
  if not proc or proc == "" then
    return nil
  end
  return (proc:match("([^\\/]+)$") or proc):gsub("%.exe$", ""):lower()
end

local function truncate(text, limit)
  if #text <= limit then
    return text
  end
  return text:sub(1, limit - 1) .. "\u{2026}"
end

-- Claude Code rings the terminal bell when it finishes or needs input. Flash the
-- pane instead of beeping, and remember which tab rang so its title can flag it.
config.audible_bell = "Disabled"
config.visual_bell = {
  fade_in_duration_ms = 60,
  fade_out_duration_ms = 180,
  target = "CursorColor",
}

local ringing = {}

wezterm.on("bell", function(window, pane)
  for _, tab in ipairs(window:mux_window():tabs()) do
    for _, p in ipairs(tab:panes()) do
      if p:pane_id() == pane:pane_id() then
        ringing[tab:tab_id()] = true
        return
      end
    end
  end
end)

wezterm.on("format-tab-title", function(tab, _, _, _, hover, max_width)
  local pane = tab.active_pane
  if tab.is_active then
    ringing[tab.tab_id] = nil
  end

  local bg, fg = INACTIVE_BG, INACTIVE_FG
  if tab.is_active then
    bg, fg = ACTIVE_BG, ACTIVE_FG
  elseif hover then
    bg, fg = HOVER_BG, HOVER_FG
  end

  -- Name only: the working directory, falling back to the process or pane title.
  local path = pane.current_working_dir and pane.current_working_dir.file_path
  if path then
    path = path:gsub("[\\/]$", "")
  end
  local folder = path and (path:match("([^\\/]+)$") or path)

  local label
  if tab.tab_title and #tab.tab_title > 0 then
    -- Manually renamed tab: trust the user's title verbatim
    label = tab.tab_title
  else
    label = folder or process_name(pane) or pane.title
  end

  -- The gap, the one cell of padding on each side and the bell take from the budget.
  local rang = ringing[tab.tab_id] or false
  label = truncate(label, math.max(10, (max_width or 40) - 3 - (rang and 2 or 0)))

  local items = {}
  for _, item in ipairs(GAP) do
    table.insert(items, item)
  end
  for _, item in ipairs {
    { Background = { Color = bg } },
    { Attribute = { Intensity = tab.is_active and "Bold" or "Normal" } },
    { Foreground = { Color = fg } },
    { Text = " " .. label },
  } do
    table.insert(items, item)
  end

  -- Claude Code rang in a tab you weren't watching: flag it in amber until you look
  if rang then
    table.insert(items, { Foreground = { Color = BELL_FG } })
    table.insert(items, { Text = " " .. ICON.bell })
  end

  table.insert(items, { Foreground = { Color = fg } })
  table.insert(items, { Text = " " })
  table.insert(items, { Attribute = { Intensity = "Normal" } })

  return items
end)

-- Ctrl+Alt+V: paste an image from the clipboard into terminal apps (e.g. Claude Code).
-- WezTerm's PasteFrom only handles text, so we dump the clipboard image to a temp PNG
-- and paste its path instead (Claude Code reads image files by path). Falls back to a
-- normal text paste when the clipboard has no image.
local paste_clipboard_image = wezterm.action_callback(function(window, pane)
  local ps = table.concat({
    "Add-Type -AssemblyName System.Windows.Forms,System.Drawing;",
    "$img=[System.Windows.Forms.Clipboard]::GetImage();",
    "if($img){",
    "  $p=Join-Path $env:TEMP ('clip-'+(Get-Date -Format yyyyMMdd-HHmmss-fff)+'.png');",
    "  $img.Save($p,[System.Drawing.Imaging.ImageFormat]::Png);",
    "  [Console]::Out.Write($p)",
    "}",
  }, " ")
  local ok, stdout = wezterm.run_child_process({ "pwsh.exe", "-NoProfile", "-Command", ps })
  if ok and stdout and #stdout > 0 then
    pane:paste(stdout)
  else
    window:perform_action(wezterm.action.PasteFrom "Clipboard", pane)
  end
end)

config.keys = {
  { key = "F11", action = wezterm.action.ToggleFullScreen },

  { key = "v", mods = "CTRL|ALT", action = paste_clipboard_image },

  { key = "s", mods = "ALT", action = wezterm.action.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" } },
  { key = "n", mods = "ALT", action = wezterm.action.PromptInputLine {
      description = "Enter workspace name",
      action = wezterm.action_callback(function(window, pane, line)
        if line and line ~= "" then
          window:perform_action(wezterm.action.SwitchToWorkspace { name = line }, pane)
        end
      end),
    },
  },
  { key = "W", mods = "ALT|SHIFT", action = wezterm.action.PromptInputLine {
      description = "Rename workspace to:",
      action = wezterm.action_callback(function(window, _, line)
        if line and line ~= "" then
          wezterm.mux.rename_workspace(window:active_workspace(), line)
        end
      end),
    },
  },

  {
    key = "F2",
    action = wezterm.action.PromptInputLine {
      description = "Enter new tab title",
      action = wezterm.action_callback(function(window, _, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
  },

  { key = "UpArrow",    mods = "CTRL|SHIFT", action = wezterm.action.ScrollByPage(-0.5) },
  { key = "DownArrow",  mods = "CTRL|SHIFT", action = wezterm.action.ScrollByPage(0.5) },
  { key = "LeftArrow",  mods = "CTRL|SHIFT", action = wezterm.action.MoveTabRelative(-1) },
  { key = "RightArrow", mods = "CTRL|SHIFT", action = wezterm.action.MoveTabRelative(1) },

  { key = "1", mods = "ALT", action = wezterm.action.ActivateTab(0) },
  { key = "2", mods = "ALT", action = wezterm.action.ActivateTab(1) },
  { key = "3", mods = "ALT", action = wezterm.action.ActivateTab(2) },
  { key = "4", mods = "ALT", action = wezterm.action.ActivateTab(3) },
  { key = "5", mods = "ALT", action = wezterm.action.ActivateTab(4) },
  { key = "6", mods = "ALT", action = wezterm.action.ActivateTab(5) },
  { key = "7", mods = "ALT", action = wezterm.action.ActivateTab(6) },
  { key = "8", mods = "ALT", action = wezterm.action.ActivateTab(7) },
  { key = "9", mods = "ALT", action = wezterm.action.ActivateTab(-1) },

  -- Panes: direct shortcuts, no leader needed (like iTerm's Cmd+D / Cmd+Shift+D)
  { key = "d", mods = "ALT", action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = "D", mods = "ALT|SHIFT", action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" } },

  { key = "h", mods = "ALT|SHIFT", action = wezterm.action.ActivatePaneDirection "Left" },
  { key = "j", mods = "ALT|SHIFT", action = wezterm.action.ActivatePaneDirection "Down" },
  { key = "k", mods = "ALT|SHIFT", action = wezterm.action.ActivatePaneDirection "Up" },
  { key = "l", mods = "ALT|SHIFT", action = wezterm.action.ActivatePaneDirection "Right" },

  { key = "LeftArrow",  mods = "LEADER", action = wezterm.action.AdjustPaneSize { "Left", 5 } },
  { key = "RightArrow", mods = "LEADER", action = wezterm.action.AdjustPaneSize { "Right", 5 } },
  { key = "UpArrow",    mods = "LEADER", action = wezterm.action.AdjustPaneSize { "Up", 5 } },
  { key = "DownArrow",  mods = "LEADER", action = wezterm.action.AdjustPaneSize { "Down", 5 } },

  { key = "z", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },
  { key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane { confirm = true } },
  { key = "w", mods = "ALT", action = wezterm.action.CloseCurrentPane { confirm = true } },

  -- Copy mode and quick select (grab paths/urls/hashes without the mouse)
  { key = "[", mods = "LEADER", action = wezterm.action.ActivateCopyMode },
  { key = "Space", mods = "LEADER", action = wezterm.action.QuickSelect },
}

return config