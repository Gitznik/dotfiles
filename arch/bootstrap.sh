#!/usr/bin/env bash
# Workstation setup for a clean, bootable Arch install. Safe to rerun.
# Never partitions disks, never overwrites existing config.
# Usage: arch/bootstrap.sh [work] [private]   (shared apps always; profile remembered)
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
common=(zsh tmux nvim lazygit workmux mise)
desktop=(hypr ghostty services swaylock screensaver waybar walker elephant tui screenshot notifications wallpaper theme)
system_services=(NetworkManager.service bluetooth.service cups.socket avahi-daemon.service ufw.service power-profiles-daemon.service docker.socket plocate-updatedb.timer fstrim.timer systemd-oomd.service)
user_services=(hyprpolkitagent.service hypridle.service elephant.service walker.service waybar.service dnd-on-screenshare.service crash-watch.service swaybg.service swayosd.service)

die() { echo "bootstrap: $*" >&2; exit 1; }
step() { echo "==> $*"; }
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
mkdir -p "$HOME"/.config/{systemd/user,environment.d,walker,elephant/menus,gtk-3.0,gtk-4.0,qt6ct} "$HOME"/.local/{bin,share,state} "$HOME"/.zsh

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

step "System tuning"
for f in sysctl.d/90-workstation.conf systemd/system.conf.d/90-workstation.conf \
  systemd/system/user@.service.d/90-faster-shutdown.conf systemd/logind.conf.d/90-workstation.conf \
  udev/rules.d/50-framework16-qmk-hid.rules; do
  install_managed "$repo/arch/etc/$f" "/etc/$f"
done
sudo sysctl --system >/dev/null
# zram swap: archinstall usually configures it already; keep whatever is there.
[[ -e /etc/systemd/zram-generator.conf ]] ||
  sudo install -Dm644 "$repo/arch/etc/systemd/zram-generator.conf" /etc/systemd/zram-generator.conf
# Lock-screen typos: Arch locks the account for 10 min after 3 failures (swaylock included).
sudo sed -i -E 's/^#? *deny *=.*/deny = 10/; s/^#? *unlock_time *=.*/unlock_time = 120/' /etc/security/faillock.conf
# Network printers and .local names (avahi): mdns before resolve/dns in nsswitch.
grep -q 'mdns_minimal' /etc/nsswitch.conf ||
  sudo sed -i -E '/^hosts:/ s/ (resolve|dns)/ mdns_minimal [NOTFOUND=return] \1/' /etc/nsswitch.conf
# Wi-Fi regulatory domain from the timezone's country, if unset.
if [[ -f /etc/conf.d/wireless-regdom ]] && ! grep -q '^WIRELESS_REGDOM=' /etc/conf.d/wireless-regdom; then
  tz=$(timedatectl show -p Timezone --value)
  cc=$(awk -v tz="$tz" '$3 == tz {print $1; exit}' /usr/share/zoneinfo/zone.tab)
  [[ $cc =~ ^[A-Z]{2}$ ]] && echo "WIRELESS_REGDOM=\"$cc\"" | sudo tee -a /etc/conf.d/wireless-regdom >/dev/null
fi

step "Hardware: GPU drivers, Framework tools"
gpu=$(lspci | grep -iE 'vga|3d|display' || true)
hw=()
if grep -qE 'Advanced Micro Devices|\[AMD' <<<"$gpu"; then
  hw+=(vulkan-radeon)
  [[ " ${profiles[*]} " == *" private "* ]] && hw+=(lib32-vulkan-radeon)
fi
if grep -q 'Intel Corporation' <<<"$gpu"; then
  hw+=(vulkan-intel intel-media-driver libvpl vpl-gpu-rt sof-firmware)
  [[ " ${profiles[*]} " == *" private "* ]] && hw+=(lib32-vulkan-intel)
  # Intel laptops: thermald (Framework recommends it on Intel models).
  ls /sys/class/power_supply/BAT* >/dev/null 2>&1 && hw+=(thermald)
fi
[[ $(cat /sys/class/dmi/id/sys_vendor 2>/dev/null) == Framework ]] && hw+=(framework-system)
if ((${#hw[@]})); then
  sudo pacman -S --needed --noconfirm "${hw[@]}"
  [[ " ${hw[*]} " == *" thermald "* ]] && sudo systemctl enable --now thermald.service
fi

step "Snapshots (btrfs root): snapper + snap-pac"
if [[ $(findmnt -no FSTYPE /) == btrfs ]]; then
  sudo pacman -S --needed --noconfirm snapper
  [[ -f /etc/snapper/configs/root ]] || sudo snapper -c root create-config /
  # Snapshots per pacman transaction only (snap-pac), keep the last 5; no hourly timeline.
  sudo snapper -c root set-config TIMELINE_CREATE=no NUMBER_CLEANUP=yes NUMBER_MIN_AGE=0 \
    NUMBER_LIMIT=5 NUMBER_LIMIT_IMPORTANT=5
  sudo pacman -S --needed --noconfirm snap-pac
  sudo systemctl enable --now snapper-cleanup.timer
  if pacman -Q limine >/dev/null 2>&1; then
    # Boot menu entries for snapshots, so a bad update can be rolled back from the boot menu.
    yay -S --needed --noconfirm --answerdiff None --answerclean None limine-snapper-sync
    sudo systemctl enable --now limine-snapper-sync.service
  else
    echo "bootstrap: snapshots are taken, but booting into one needs Limine (see README step 1)" >&2
  fi
else
  echo "bootstrap: root isn't btrfs, skipping snapshots" >&2
fi

step "Firewall: deny incoming, allow LocalSend"
sudo ufw default deny incoming >/dev/null
sudo ufw default allow outgoing >/dev/null
sudo ufw allow 53317/tcp comment LocalSend >/dev/null
sudo ufw allow 53317/udp comment LocalSend >/dev/null
# Keep SSH reachable where sshd is enabled (e.g. the test VM), rate-limited.
if systemctl is-enabled --quiet sshd.service 2>/dev/null; then sudo ufw limit 22/tcp comment SSH >/dev/null; fi
# Containers resolve DNS via the docker bridge; incoming is denied otherwise.
sudo ufw allow in proto udp from 172.16.0.0/12 to 172.17.0.1 port 53 comment docker-dns >/dev/null
sudo ufw allow in proto udp from 192.168.0.0/16 to 172.17.0.1 port 53 comment docker-dns >/dev/null
sudo ufw --force enable >/dev/null

step "Keyring (empty password; the disk is LUKS-encrypted and auto-login types none)"
kr=$HOME/.local/share/keyrings
if ! compgen -G "$kr/*.keyring" >/dev/null; then
  mkdir -p "$kr" && chmod 700 "$kr"
  printf '[keyring]\ndisplay-name=Default keyring\nctime=%s\nmtime=0\nlock-on-idle=false\nlock-after=false\n' \
    "$(date +%s)" >"$kr/Default_keyring.keyring"
  chmod 600 "$kr/Default_keyring.keyring"
  echo Default_keyring >"$kr/default"
fi

step "Web apps (arch/webapps.txt)"
apps_dir=$HOME/.local/share/applications icons_dir=$HOME/.local/share/icons/webapps
mkdir -p "$apps_dir" "$icons_dir"
wanted=()
while IFS='|' read -r prof name url icon; do
  prof=$(xargs <<<"$prof") name=$(xargs <<<"$name") url=$(xargs <<<"$url") icon=$(xargs <<<"$icon")
  [[ -z $prof || $prof == \#* ]] && continue
  [[ $prof == shared || " ${profiles[*]} " == *" $prof "* ]] || continue
  slug=$(tr '[:upper:] ' '[:lower:]-' <<<"$name")
  host=${url#*://}; host=${host%%/*}
  [[ -f $icons_dir/$slug.png ]] || curl -fsSL "$icon" -o "$icons_dir/$slug.png" || echo "bootstrap: no icon for $name" >&2
  cat >"$apps_dir/webapp-$slug.desktop" <<DESKTOP
[Desktop Entry]
# Managed by arch/bootstrap.sh (arch/webapps.txt)
Type=Application
Name=$name
Exec=chromium --app=$url
Icon=$icons_dir/$slug.png
StartupWMClass=chrome-${host}__-Default
Categories=Network;
DESKTOP
  wanted+=("webapp-$slug.desktop")
done <"$repo/arch/webapps.txt"
# Drop generated entries that are no longer listed.
for f in "$apps_dir"/webapp-*.desktop; do
  [[ -e $f ]] || continue
  grep -q 'Managed by arch/bootstrap.sh' "$f" && [[ " ${wanted[*]} " != *" ${f##*/} "* ]] && rm -f "$f"
done

step "Services"
sudo systemctl enable --now "${system_services[@]}"
if ! id -nG "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
  echo "bootstrap: added $USER to the docker group (takes effect at next login)"
fi
systemctl --user enable "${user_services[@]}"
# Sockets are safe to start outside a session; the keyring is then reachable right away.
systemctl --user enable --now gnome-keyring-daemon.socket
# On a rerun inside a session: elephant only loads providers at startup, so new ones need a restart.
systemctl --user try-restart elephant.service walker.service 2>/dev/null || true

step "Default apps"
xdg-user-dirs-update
mime() { local app=$1; shift; xdg-mime default "$app" "$@"; }
xdg-settings set default-web-browser zen.desktop
mime zen.desktop x-scheme-handler/http x-scheme-handler/https text/html application/xhtml+xml
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
