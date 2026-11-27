#!/usr/bin/env bash
# Workstation setup for a clean, bootable Arch install. Safe to rerun.
# Never partitions disks, never overwrites existing config.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
common=(zsh tmux nvim lazygit workmux mise)
desktop=(hypr ghostty services swaylock screensaver)
system_services=(NetworkManager.service bluetooth.service)
user_services=(hyprpolkitagent.service hypridle.service elephant.service walker.service)

die() { echo "bootstrap: $*" >&2; exit 1; }
step() { echo "==> $*"; }

[[ $EUID -ne 0 ]] || die "run as your user, not root"
grep -qx 'ID=arch' /etc/os-release || die "not Arch Linux"

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

# Real dirs first, so stow links files inside them instead of folding whole dirs into the repo.
mkdir -p "$HOME"/.config/systemd/user "$HOME"/.local/{bin,share,state} "$HOME"/.zsh

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

step "Services"
sudo systemctl enable --now "${system_services[@]}"
systemctl --user enable "${user_services[@]}"

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

if [[ $(getent passwd "$USER" | cut -d: -f7) != /usr/bin/zsh ]]; then
  step "Login shell -> zsh"
  chsh -s /usr/bin/zsh
fi

step "Done. Reboot to log in via greetd."
