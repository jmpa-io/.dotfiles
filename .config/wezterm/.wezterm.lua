local wezterm = require 'wezterm'

local config = wezterm.config_builder()

config.font = wezterm.font { family = 'FiraCode Nerd Font Mono', weight = 'Regular' }
config.font_size = 10

config.color_scheme = "Dracula (Official)"
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.window_decorations = "RESIZE"
config.warn_about_missing_glyphs = false

return config
