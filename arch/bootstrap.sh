#!/usr/bin/env bash
# Workstation setup for a clean, bootable Arch install. Safe to rerun.
# Never partitions disks, never overwrites existing config.
# Usage: arch/bootstrap.sh [work] [private]   (shared apps always; profile remembered)
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
common=(zsh tmux nvim lazygit workmux mise)
desktop=(hypr ghostty services swaylock screensaver waybar walker elephant tui screenshot notifications wallpaper theme)
system_services=(NetworkManager.service bluetooth.service cups.socket ufw.service power-profiles-daemon.service docker.socket plocate-updatedb.timer)
user_services=(hyprpolkitagent.service hypridle.service elephant.service walker.service waybar.service dnd-on-screenshare.service crash-watch.service swaybg.service swayosd.service gnome-keyring-daemon.socket)

die() { echo "bootstrap: $*" >&2; exit 1; }
step() { echo "==> $*"; }

[[ $EUID -ne 0 ]] || die "run as your user, not root"
grep -qx 'ID=arch' /etc/os-release || die "not Arch Linux"

# Which app lists this machine gets (besides shared). Arguments replace the remembered set.
profile_file=$HOME/.config/dotfiles-profile
if (($#)); then
  for p in "$@"; do [[ $p == work || $p == private ]] || die "unknown profile '$p' (use work and/or private)"; done
  mkdir -p "$(dirname "$profile_file")"
  printf '%s\n' "$@" >"$profile_file"
fi
profiles=()
[[ -f $profile_file ]] && mapfile -t profiles <"$profile_file"
echo "bootstrap: app profiles: shared ${profiles[*]:-(no work/private; pass 'work' and/or 'private')}"
if [[ " ${profiles[*]} " == *" private "* ]] && ! grep -q '^\[multilib\]' /etc/pacman.conf; then
  die "the private apps need [multilib] (steam): uncomment it in /etc/pacman.conf, run 'sudo pacman -Sy', rerun"
fi

step "Official packages"
grep -v -E '^\s*(#|$)' "$repo/arch/packages-repo.txt" | sudo pacman -S --needed --noconfirm -

step "AUR packages"
if ! command -v yay >/dev/null; then
  build=$(mktemp -d)
  git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$build/yay-bin"
  (cd "$build/yay-bin" && makepkg -si --noconfirm --needed)
  rm -rf "$build"
fi
mapfile -t aur < <(grep -v -E '^\s*(#|$)' "$repo/arch/packages-aur.txt")
yay -S --needed --noconfirm --answerdiff None --answerclean None --removemake "${aur[@]}"

step "Apps: shared ${profiles[*]}"
apps=()
for list in shared "${profiles[@]}"; do
  mapfile -t -O "${#apps[@]}" apps < <(grep -v -E '^\s*(#|$)' "$repo/arch/apps-$list.txt")
done
yay -S --needed --noconfirm --answerdiff None --answerclean None --removemake "${apps[@]}"

# Real dirs first, so stow links files inside them instead of folding whole dirs into the repo.
mkdir -p "$HOME"/.config/{systemd/user,walker,elephant/menus,gtk-3.0,gtk-4.0,qt6ct} "$HOME"/.local/{bin,share,state} "$HOME"/.zsh

step "Checking for config conflicts"
if ! stow -n -d "$repo" -t "$HOME" "${common[@]}" 2>/tmp/bootstrap-stow.$$ ||
   ! stow -n -d "$repo/arch/stow" -t "$HOME" "${desktop[@]}" 2>>/tmp/bootstrap-stow.$$; then
  cat /tmp/bootstrap-stow.$$ >&2; rm -f /tmp/bootstrap-stow.$$
  die "existing files would be overwritten; move them aside and rerun"
fi
rm -f /tmp/bootstrap-stow.$$

step "Linking dotfiles"
# Not -R: restowing the root packages walks ~/.local/bin, sees links into arch/stow and treats
# arch/ as a missing root package. Plain stow is idempotent; remove stale links with stow -D.
stow -d "$repo" -t "$HOME" "${common[@]}"
stow -d "$repo/arch/stow" -t "$HOME" "${desktop[@]}"

step "mise tools (global config)"
mise install --yes

step "Dark GTK/Qt theme"
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
gsettings set org.gnome.desktop.interface icon-theme Adwaita
gsettings set org.gnome.desktop.interface cursor-theme Adwaita
gsettings set org.gnome.desktop.interface cursor-size 24
# qt6ct needs an absolute scheme path, so its config is rendered, and only if missing:
# qt6ct rewrites the file when you change settings in its GUI.
[[ -e $HOME/.config/qt6ct/qt6ct.conf ]] ||
  sed "s|@HOME@|$HOME|" "$repo/arch/etc/qt6ct/qt6ct.conf" >"$HOME/.config/qt6ct/qt6ct.conf"

step "Firewall: deny incoming, allow LocalSend"
sudo ufw default deny incoming >/dev/null
sudo ufw default allow outgoing >/dev/null
sudo ufw allow 53317/tcp comment LocalSend >/dev/null
sudo ufw allow 53317/udp comment LocalSend >/dev/null
# Keep SSH reachable where sshd is enabled (e.g. the test VM), rate-limited.
if systemctl is-enabled --quiet sshd.service 2>/dev/null; then sudo ufw limit 22/tcp comment SSH >/dev/null; fi
sudo ufw --force enable >/dev/null

step "Services"
sudo systemctl enable --now "${system_services[@]}"
if ! id -nG "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
  echo "bootstrap: added $USER to the docker group (takes effect at next login)"
fi
systemctl --user enable "${user_services[@]}"
# On a rerun inside a session: elephant only loads providers at startup, so new ones need a restart.
systemctl --user try-restart elephant.service walker.service 2>/dev/null || true

step "Default apps"
xdg-user-dirs-update
mime() { local app=$1; shift; xdg-mime default "$app" "$@"; }
mime org.gnome.Nautilus.desktop inode/directory
mime org.gnome.Papers.desktop application/pdf
mime imv.desktop image/png image/jpeg image/gif image/webp image/bmp image/tiff image/avif image/heic image/svg+xml
mime mpv.desktop video/mp4 video/webm video/x-matroska video/quicktime video/x-msvideo video/mpeg video/ogg \
  audio/mpeg audio/flac audio/ogg audio/wav audio/x-wav audio/mp4 audio/aac audio/opus

step "Boot splash (Plymouth theme)"
theme_src="$repo/arch/plymouth/gitznik" theme_dst=/usr/share/plymouth/themes/gitznik
if ! diff -rq "$theme_src" "$theme_dst" >/dev/null 2>&1; then
  sudo rm -rf "$theme_dst"
  sudo cp -r "$theme_src" "$theme_dst"
  theme_changed=1
fi
if [[ $(plymouth-set-default-theme) != gitznik || ${theme_changed:-0} == 1 ]]; then
  sudo plymouth-set-default-theme -R gitznik   # -R rebuilds the initramfs
fi
# grep exits 2 when mkinitcpio.conf.d/ has no *.conf; keep that from failing the check under pipefail.
hooks=$(grep -hsE '^\s*HOOKS(\+)?=' /etc/mkinitcpio.conf /etc/mkinitcpio.conf.d/*.conf || true)
grep -qw plymouth <<<"$hooks" ||
  echo "bootstrap: WARNING: no plymouth hook in mkinitcpio HOOKS, so the theme won't show (see README step 1)" >&2
grep -qw splash /proc/cmdline ||
  echo "bootstrap: WARNING: 'splash' missing from kernel cmdline, so the theme won't show (see README step 1)" >&2

step "Login: greetd auto-login"
greetd_conf=$(sed "s/@USER@/$USER/" "$repo/arch/etc/greetd/config.toml")
if ! diff -q <(echo "$greetd_conf") /etc/greetd/config.toml >/dev/null 2>&1; then
  pacman -Qii greetd | grep -qF '/etc/greetd/config.toml [unmodified]' ||
    die "/etc/greetd/config.toml was edited locally; merge arch/etc/greetd/config.toml by hand"
  echo "$greetd_conf" | sudo install -m644 /dev/stdin /etc/greetd/config.toml
fi
# Enable only: starting greetd now would take over tty1 mid-bootstrap. Active after reboot.
sudo systemctl enable greetd.service

step "Login screen: tuigreet theme, Catppuccin console palette"
# Installs a repo file into /etc. Replaces only files this script wrote (marker line), so
# hand edits stop the run instead of being overwritten.
install_managed() {
  local src=$1 dst=$2
  cmp -s "$src" "$dst" && return 0
  if [[ -e $dst ]] && ! grep -q 'Managed by arch/bootstrap.sh' "$dst"; then
    die "$dst exists and wasn't written by this script; merge $src by hand"
  fi
  sudo install -Dm644 "$src" "$dst"
}
install_managed "$repo/arch/etc/tuigreet/config.toml" /etc/tuigreet/config.toml
install_managed "$repo/arch/etc/systemd/system/vtrgb-catppuccin.service" /etc/systemd/system/vtrgb-catppuccin.service
# Own filename and no room for a marker in the palette format, so always kept in sync.
cmp -s "$repo/arch/etc/vtrgb-catppuccin" /etc/vtrgb-catppuccin ||
  sudo install -m644 "$repo/arch/etc/vtrgb-catppuccin" /etc/vtrgb-catppuccin
sudo systemctl daemon-reload
sudo systemctl enable --now vtrgb-catppuccin.service

if [[ $(getent passwd "$USER" | cut -d: -f7) != /usr/bin/zsh ]]; then
  step "Login shell -> zsh"
  chsh -s /usr/bin/zsh
fi

step "Done. Reboot to log in via greetd."
