local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Font.
config.font = wezterm.font { family = 'FiraCode Nerd Font Propo', weight = 'Regular' }
config.font_size = 10

-- Theme.
config.color_scheme = "Dracula (Official)"
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.window_decorations = "RESIZE"
config.warn_about_missing_glyphs = false

-- Underlines.
config.underline_position = -6
config.underline_thickness = '250%'

return config
