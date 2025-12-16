local wezterm = require 'wezterm'

local config = wezterm.config_builder()


config.font = wezterm.font("MesloLGS Nerd Font Mono")

config.color_scheme = "Japanesque"

config.enable_tab_bar = false
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 20

config.keys = {
  {key="Enter", mods="SHIFT", action=wezterm.action{SendString="\x1b\r"}},
}

return config
