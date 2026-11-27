local function bind(keys, action, opts)
  if type(action) == "string" then
    action = hl.dsp.exec_cmd("uwsm-app -- " .. action)
  end
  hl.bind(keys, action, opts or {})
end

bind("SUPER + RETURN", "ghostty")
bind("SUPER + D", hl.dsp.exec_cmd("walker"))
bind("SUPER + E", "nautilus --new-window")
bind("PRINT", hl.dsp.exec_cmd("$HOME/.local/bin/screenshot"))
bind("SUPER + CTRL + V", hl.dsp.exec_cmd("walker -m clipboard"))

bind("SUPER + W", hl.dsp.window.close())
bind("SUPER + T", hl.dsp.window.float({ action = "toggle" }))
bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind("SUPER + S", hl.dsp.layout("togglesplit"))
bind("SUPER + ESCAPE", hl.dsp.exec_cmd("walker -m menus:system"))
bind("SUPER + SHIFT + ESCAPE", hl.dsp.exec_cmd("uwsm stop"))
bind("SUPER + CTRL + L", hl.dsp.exec_cmd("loginctl lock-session"))

for key, dir in pairs({ H = "l", J = "d", K = "u", L = "r" }) do
  bind("SUPER + " .. key, hl.dsp.focus({ direction = dir }))
  bind("SUPER + SHIFT + " .. key, hl.dsp.window.swap({ direction = dir }))
end

for ws = 1, 10 do
  local key = tostring(ws % 10)
  bind("SUPER + " .. key, hl.dsp.focus({ workspace = tostring(ws) }))
  bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(ws), follow = true }))
end

bind("switch:on:Lid Switch", hl.dsp.exec_cmd("$HOME/.local/bin/clamshell"), { locked = true })
bind("switch:off:Lid Switch", hl.dsp.exec_cmd("$HOME/.local/bin/clamshell"), { locked = true })

-- Media and brightness keys: work on the lock screen, repeat while held. swayosd shows the level.
local held = { locked = true, repeating = true }
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), held)
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), held)
bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { locked = true })
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"), held)
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), held)
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
