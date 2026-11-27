local function bind(keys, action, opts)
  if type(action) == "string" then
    action = hl.dsp.exec_cmd("uwsm-app -- " .. action)
  end
  hl.bind(keys, action, opts or {})
end

bind("SUPER + RETURN", "ghostty")
bind("SUPER + D", hl.dsp.exec_cmd("walker"))
bind("SUPER + E", "nautilus --new-window")

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

bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
