# Arch workstation

Plain Arch + Hyprland, no Omarchy. Shared dotfiles (`zsh tmux nvim lazygit workmux`) live at the repo root. The Arch-only desktop lives in `arch/stow/` (`hypr ghostty services swaylock screensaver`), plus `arch/etc/` for system files. The Omarchy machine keeps using `just stow-all` on `main` and never stows `arch/stow/`.

## 1. Base install (per machine, by hand or `archinstall`)

Decide these per machine. Don't script them:

- [ ] Target disk confirmed (`lsblk`). Don't use the daily driver's disk.
- [ ] LUKS full-disk encryption (required: auto-login relies on the disk passphrase), bootloader, kernel (`linux` + `linux-headers`), microcode (`amd-ucode`/`intel-ucode`)
- [ ] User in `wheel` with sudo
- [ ] Packages: `base base-devel git networkmanager`, with `NetworkManager` enabled so the first boot has network
- [ ] Boots to a TTY login

Keep Wi-Fi passwords, SSH/GPG keys and tokens out of this repo.

## 2. Workstation bootstrap

```sh
git clone git@github.com:Gitznik/dotfiles.git ~/dotfiles   # or https:// before SSH keys exist
cd ~/dotfiles && git switch arch
arch/bootstrap.sh
```

The bootstrap installs `packages-repo.txt`, checks for conflicts with existing files, stows the shared and desktop packages, installs the greetd config, enables services and sets zsh as the login shell. If any file would be overwritten, it stops before changing anything. Rerunning it is safe.

AUR packages (`packages-aur.txt`: walker, elephant and its providers, ttfx, zen-browser) are only listed. Review each PKGBUILD and build it yourself; walker won't work until you do.

Reboot. After the LUKS passphrase, greetd logs you straight into Hyprland (via uwsm). After logging out, tuigreet asks for your password.

## 3. VM test loop

The VM needs a virtio GPU with 3D/GL acceleration, or Hyprland won't start.

1. Install base Arch (step 1), then snapshot it as **clean-base**.
2. Run step 2 from the branch.
3. Run the checks below. Fix problems **in the repo** (push, then pull in the guest), not by hand in the guest.
4. Reboot, rerun `arch/bootstrap.sh`: no errors, nothing duplicated, no config overwritten.
5. Restore **clean-base**, repeat step 2 and pass the checks with no manual fixes.
6. Record the result: `git rev-parse --short HEAD` and `pacman -Q hyprland uwsm ghostty walker-bin elephant-bin`.

### Milestone 1 checks

- [ ] Boot: LUKS passphrase, then straight into Hyprland (no second password). Catppuccin borders, no Hyprland logo or splash
- [ ] Log out: tuigreet appears, and logging back in works
- [ ] `SUPER+RETURN` opens Ghostty (Catppuccin Mocha) with zsh, prompt and plugins and no startup errors; `tmux` starts
- [ ] `SUPER+D` opens walker and launches apps; `systemctl --user status elephant walker` shows both running
- [ ] `SUPER+HJKL` focus, `SUPER+SHIFT+HJKL` swap, `SUPER+S` toggle split, `SUPER+T` float, `SUPER+F` fullscreen with no border, `SUPER+W` close
- [ ] `SUPER+1…0` / `SUPER+SHIFT+1…0` switch and move windows across workspaces
- [ ] `SUPER+SHIFT+ESCAPE` leaves the session cleanly
- [ ] `hyprctl configerrors` is empty
- [ ] Idle: screensaver at 150s (fullscreen ttfx text effects on black, own special workspace, tiled layout untouched); a key press or mouse move closes it and restores the cursor
- [ ] Lock: `SUPER+CTRL+L` locks (Catppuccin swaylock); idle locks at 300s over the screensaver, display turns off at 330s, a key press wakes it to the lock screen
- [ ] Suspend (`systemctl suspend`) locks first; on resume the lock screen shows, never the unlocked desktop
- [ ] Locker robustness (hardware first; hyprlock crashed here when the display turned off while locked, see hyprwm/hyprlock#953): lock, then 10× `hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'` / `enable` from another TTY: swaylock survives. Then `pkill -9 swaylock`: the session **stays locked** (Hyprland's "lockscreen died" screen), and `swaylock` started from a TTY with `WAYLAND_DISPLAY` set takes over and unlocks normally

### Later milestones (from the inventory)

1. Bar with Bluetooth / Wi-Fi / audio controls; clock showing the UTC offset; system menu (lock/suspend/reboot) in walker via `elephant-menus`
2. Screenshot on `PRINT`; clipboard history via `elephant-clipboard`
3. Notifications with DND + screen-share DND script; crash notifications
4. Hardware: dock/lid, suspend/resume, second display (workspaces stay global), portal screen sharing
