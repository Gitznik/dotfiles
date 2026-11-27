-- Plain Hyprland config for the Arch workstation. No Omarchy helpers.
package.path = os.getenv("HOME") .. "/.config/?.lua;" .. package.path

for _, module in ipairs({ "hypr.env", "hypr.monitors", "hypr.input", "hypr.looknfeel", "hypr.bindings", "hypr.autostart" }) do
  package.loaded[module] = nil
  require(module)
end
