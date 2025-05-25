local wezterm = require 'wezterm'
return {
  font = wezterm.font { family = 'FiraCode Nerd Font Propo', weight = 'Regular' },
  font_size = 10,

  color_scheme = "Dracula (Official)",
  tab_bar_at_bottom = true,
  use_fancy_tab_bar = false,
  window_decorations = "RESIZE",
  warn_about_missing_glyphs = false
}
