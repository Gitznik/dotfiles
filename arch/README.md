# Arch workstation

Plain Arch + Hyprland, no Omarchy. Shared dotfiles (`zsh tmux nvim lazygit workmux`) live at the repo root. The Arch-only desktop lives in `arch/stow/` (`hypr ghostty services swaylock screensaver waybar walker elephant tui`), plus `arch/etc/` for system files. The Omarchy machine keeps using `just stow-all` on `main` and never stows `arch/stow/`.

## 1. Base install (per machine, by hand or `archinstall`)

Decide these per machine. Don't script them:

- [ ] Target disk confirmed (`lsblk`). Don't use the daily driver's disk.
- [ ] LUKS full-disk encryption (required: auto-login relies on the disk passphrase), bootloader, kernel (`linux` + `linux-headers`), microcode (`amd-ucode`/`intel-ucode`)
- [ ] Boot splash for the LUKS prompt: `plymouth` package installed, `plymouth` in mkinitcpio `HOOKS` after `base udev`/`systemd` and before `encrypt`/`sd-encrypt`, `quiet splash` on the kernel command line (bootloader-specific; with a UKI it's `/etc/kernel/cmdline`), then `mkinitcpio -P`. The bootstrap installs the theme and warns if the hook or `splash` is missing. A serial console on the command line (`console=ttyS0`/`uart`) makes Plymouth fall back to text
- [ ] User in `wheel` with sudo
- [ ] Packages: `base base-devel git networkmanager`, with `NetworkManager` enabled so the first boot has network
- [ ] Boots to a TTY login

Keep Wi-Fi passwords, SSH/GPG keys and tokens out of this repo. SSH keys live in Bitwarden: pull them from there on each machine (step 2), never copy them between machines or commit them.

## 2. Workstation bootstrap

```sh
git clone https://github.com/Gitznik/dotfiles.git ~/dotfiles   # SSH keys aren't on the machine yet
cd ~/dotfiles && git switch arch
arch/bootstrap.sh
```

**Real machines only (not the VM):** pull the SSH keys from Bitwarden into `~/.ssh` (`chmod 700 ~/.ssh`, `600` on private keys), then switch the remote: `git -C ~/dotfiles remote set-url origin git@github.com:Gitznik/dotfiles.git`. Use the Bitwarden desktop app or `bitwarden-cli` (official repo). **Open:** exact item names and storage type (SSH-key items or attachments), and whether to script this step.

The bootstrap installs `packages-repo.txt` and `packages-aur.txt`, checks for conflicts with existing files, stows the shared and desktop packages, installs the greetd config, enables services and sets zsh as the login shell. If any file would be overwritten, it stops before changing anything. Rerunning it is safe.

AUR packages (`packages-aur.txt`: walker, elephant and its providers, ttfx, zen-browser) are installed with yay, which the bootstrap installs first if missing. PKGBUILDs are not reviewed; the list prefers `-bin` packages that repackage upstream release binaries.

Reboot. After the LUKS passphrase, greetd logs you straight into Hyprland (via uwsm). After logging out, tuigreet asks for your password.

## 3. VM test loop

The VM needs a virtio GPU with 3D/GL acceleration, or Hyprland won't start. `just vm …` (`arch/vm/vm.sh`, needs `qemu-desktop edk2-ovmf`) provides this. Images live in `~/vms` (on btrfs: `chattr +C ~/vms` before creating them). On a Hyprland host, press `Ctrl+Alt+G` in the VM window before using `SUPER` bindings, or the host takes them.

1. Install base Arch (step 1) with `just vm iso` then `just vm create`, then snapshot it as **clean-base** with `just vm seal`. Restore it with `just vm reset`; boot with `just vm run`.
2. Run step 2 from the branch.
3. Run the checks below. Fix problems **in the repo** (push, then pull in the guest), not by hand in the guest.
4. Reboot, rerun `arch/bootstrap.sh`: no errors, nothing duplicated, no config overwritten.
5. Restore **clean-base**, repeat step 2 and pass the checks with no manual fixes.
6. Record the result: `git rev-parse --short HEAD` and `pacman -Q hyprland uwsm ghostty walker-bin elephant-bin waybar`.

### Milestone 1 checks

- [ ] LUKS prompt shows the Gitznik Plymouth theme (Catppuccin Mocha, lock icon, password box); a wrong passphrase re-prompts
- [ ] Boot: LUKS passphrase, then straight into Hyprland (no second password). Catppuccin borders, no Hyprland logo or splash
- [ ] Log out: tuigreet appears, and logging back in works
- [ ] `SUPER+RETURN` opens Ghostty (Catppuccin Mocha) with zsh, prompt and plugins and no startup errors; `tmux` starts
- [ ] `SUPER+D` opens walker and launches apps; `systemctl --user status elephant walker` shows both running
- [ ] `SUPER+HJKL` focus, `SUPER+SHIFT+HJKL` swap, `SUPER+S` toggle split, `SUPER+T` float, `SUPER+F` fullscreen with no border, `SUPER+W` close
- [ ] `SUPER+1…0` / `SUPER+SHIFT+1…0` switch and move windows across workspaces
- [ ] `SUPER+SHIFT+ESCAPE` leaves the session cleanly
- [ ] `hyprctl configerrors` is empty
- [ ] Idle: screensaver at 150s (fullscreen ttfx text effects on black, own special workspace, tiled layout untouched); a key press or mouse move closes it and restores the cursor
  - **Open (2026-11-27):** fails in the VM (Hyprland 0.57.2): every new window resets idle, so the screensaver window triggers hypridle's resume, which kills it, and the 300s lock is never reached. Plain windows reproduce it; hiding the cursor doesn't. Unknown whether it's Hyprland or QEMU's absolute tablet. Verify on hardware first
- [ ] Lock: `SUPER+CTRL+L` locks (Catppuccin swaylock); idle locks at 300s over the screensaver, display turns off at 330s, a key press wakes it to the lock screen
- [ ] Suspend (`systemctl suspend`) locks first; on resume the lock screen shows, never the unlocked desktop
- [ ] Locker robustness (hardware first; hyprlock crashed here when the display turned off while locked, see hyprwm/hyprlock#953): lock, then 10× `hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'` / `enable` from another TTY: swaylock survives. Then `pkill -9 swaylock`: the session **stays locked** (Hyprland's "lockscreen died" screen), and `swaylock` started from a TTY with `WAYLAND_DISPLAY` set takes over and unlocks normally

### Milestone 2 checks (bar and quick controls)

- [ ] Waybar starts with the session (`systemctl --user status waybar`): workspaces left, clock center, tray / Bluetooth / network / audio / battery / power right. Catppuccin colors; Nerd Font icons render (no boxes)
- [ ] Clock shows date, time and UTC offset (e.g. `UTC+0100`); hovering shows a month calendar
- [ ] Workspace buttons follow `SUPER+1…0` and switch on click
- [ ] Bluetooth icon: click opens `bluetui` as a centered floating window; clicking again focuses it instead of opening a second one. Pair/connect a device (hardware)
- [ ] Network icon: click opens `nmtui connect`; switching Wi-Fi works (hardware; the VM only has ethernet)
- [ ] Audio icon: click opens `wiremix`, scroll changes volume, right-click mutes (icon dims)
- [ ] Battery shows on laptops, is hidden in the VM
- [ ] `SUPER+ESCAPE` and the power icon open the System menu; typing `lock`/`suspend` in `SUPER+D` finds the same entries. Lock, log out and reboot work from it

### Later milestones (from the inventory)

1. Screenshot on `PRINT`; clipboard history via `elephant-clipboard`
2. Notifications with DND + screen-share DND script; crash notifications
3. Hardware: dock/lid, suspend/resume, second display (workspaces stay global), portal screen sharing

## Notes

- **Plymouth theme** (`arch/plymouth/gitznik`): adapted from Omarchy 4.5.0's theme (MIT, `LICENSE` alongside). To change the logo text, re-render `logo.png`:
  `magick -background none -fill '#cba6f7' +antialias -font JetBrainsMono-NF-Bold -pointsize 13 label:Gitznik -trim +repage -filter point -resize 1300% logo.png`
  (pixel style; for smooth letters, drop `+antialias … -resize 1300%` and use `-pointsize 170`). Then rerun the bootstrap.
