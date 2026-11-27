-- Catppuccin Mocha: mauve active, surface1 inactive.
hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 2,
    col = { active_border = "rgb(cba6f7)", inactive_border = "rgb(45475a)" },
    resize_on_border = true,
    layout = "dwindle",
  },
  decoration = {
    rounding = 4,
    shadow = { enabled = false },
    blur = { enabled = false },
  },
  animations = { enabled = false },
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
    -- If the locker dies the session stays locked; this lets a new locker take over.
    allow_session_lock_restore = true,
  },
})

hl.window_rule({ match = { fullscreen = true }, border_size = 0 })

-- Screenshot annotation (satty): app id differs between versions.
hl.window_rule({ match = { class = "(com\\.gabm\\.satty|org\\.satty\\.satty)" }, float = true, center = true })

hl.window_rule({ match = { class = "local.screensaver" }, workspace = "special:screensaver", fullscreen = true })
