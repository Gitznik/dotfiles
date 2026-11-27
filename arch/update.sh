#!/usr/bin/env bash
# just update: system packages (snap-pac snapshots each transaction), dotfiles + bootstrap
# (new packages and config), mise tools, firmware check. Interactive: read what it prints.
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
step() { printf '\n==> %s\n' "$*"; }

step "Dotfiles"
git -C "$repo" pull --ff-only

step "System packages (official repos + AUR)"
yay -Syu --answerdiff None --answerclean None

step "Bootstrap (applies new packages and config from the dotfiles)"
"$repo/arch/bootstrap.sh"

step "mise tools"
mise upgrade --yes

step "Firmware (fwupd; install with: fwupdmgr update)"
fwupdmgr refresh --force >/dev/null 2>&1 || true
fwupdmgr get-updates || true   # exits non-zero when there's nothing to do

pkill -RTMIN+10 -x waybar || true   # refresh the bar's update indicator
step "Done. Reboot if the kernel or systemd was updated."
