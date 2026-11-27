-- Host-specific outputs go here. Workspaces stay global (not per monitor).
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Clamshell (docked, lid closed): ~/.local/bin/clamshell turns the laptop panel off while
-- another display is connected. Re-checked whenever the lid or the set of displays changes.
local clamshell = os.getenv("HOME") .. "/.local/bin/clamshell"
for _, event in ipairs({ "hyprland.start", "config.reloaded", "monitor.added", "monitor.removed" }) do
  hl.on(event, function() hl.exec_cmd(clamshell) end)
end
