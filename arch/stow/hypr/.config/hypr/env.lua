hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
-- SSH keys live in Bitwarden: its desktop app serves them as an SSH agent (Settings > SSH agent).
hl.env("SSH_AUTH_SOCK", os.getenv("HOME") .. "/.bitwarden-ssh-agent.sock")

hl.config({
  xwayland = { force_zero_scaling = true },
  ecosystem = { no_update_news = true, no_donation_nag = true },
})
