-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Command palette back on SUPER+D (was SUPER+SPACE)
hl.unbind("SUPER + SPACE")
o.bind("SUPER + D", "Omarchy menu", "omarchy-menu toggle")

-- Vim-style focus/swap (displaces: J=togglesplit, K=keybindings, L=workspace layout)
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
hl.unbind("SUPER + ALT + L") -- no workspace layout cycling (scrolling/floating)
for key, dir in pairs({ H = "l", J = "d", K = "u", L = "r" }) do
  o.bind("SUPER + " .. key, nil, hl.dsp.focus({ direction = dir }))
  o.bind("SUPER + SHIFT + " .. key, nil, hl.dsp.window.swap({ direction = dir }))
end

-- Old homes for displaced/changed defaults
hl.unbind("SUPER + S")
hl.unbind("SUPER + CTRL + S")
hl.unbind("SUPER + CTRL + K")
o.bind("SUPER + S", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + CTRL + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + CTRL + K", "Keybindings", "omarchy-menu-keybindings")
o.bind("SUPER + E", "File manager", { launch = "nautilus --new-window" })
