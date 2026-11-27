-- Bar popups (tui-launch): bluetui, nmtui, wiremix. They float top right, just below the
-- bar (26px) and gaps_out, and close like a popover when focus moves to another window.
local class = "local\\.tui\\..+"

hl.window_rule({
  match = { class = class },
  float = true,
  size = { 800, 500 },
  move = { "(monitor_w-window_w-10)", "36" },
})

local popup = nil

hl.on("window.active", function(window)
  if popup and (not window or window.address ~= popup) then
    local target = "address:" .. popup
    popup = nil
    if hl.get_window(target) then
      hl.dispatch(hl.dsp.window.close({ window = target }))
    end
  end
  if window and window.class and window.class:match("^local%.tui%.") then
    popup = window.address
  end
end)
