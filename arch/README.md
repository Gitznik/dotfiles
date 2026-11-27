# Arch workstation

Plain Arch + Hyprland, no Omarchy. Shared dotfiles (`zsh tmux nvim lazygit workmux`) live at the repo root. The Arch-only desktop lives in `arch/stow/` (`hypr ghostty services swaylock screensaver waybar walker elephant tui screenshot notifications wallpaper theme`), plus `arch/etc/` for system files (greetd, tuigreet theme, Catppuccin console palette). The Omarchy machine keeps using `just stow-all` on `main` and never stows `arch/stow/`.

## 1. Base install (archinstall)

Boot the Arch ISO and run `archinstall`. Pick these, leave everything else at the default:

- **Disk:** the target disk (check with `lsblk`; never the daily driver's), **btrfs** with the default subvolumes, **encryption on** (LUKS; auto-login relies on the disk passphrase)
- **Bootloader:** **Limine**, UKI off (snapshots then show up in the boot menu)
- **Swap:** zram on
- **Network:** NetworkManager
- **Profile:** Minimal. **Additional packages:** `git`
- **User:** your user, with sudo (superuser)
- **Private machines:** enable the `multilib` repository (Steam)

Nothing to edit by hand afterwards: the bootstrap adds the boot splash (Plymouth hook, `quiet splash`) and the snapshot boot entries. The test VM does all of this from a config file: `archinstall --config user_configuration.json` (from `arch/vm/`), which also adds `openssh` + `sshd`. **Passwords aren't in the file:** in archinstall's menu set the user (Authentication) **and** the disk encryption password (Disk configuration > Disk encryption) before Install. Without the encryption password archinstall silently installs unencrypted; the bootstrap refuses to run on an unencrypted root.

**Framework laptops** (the plan for all machines): update the BIOS first (`fwupdmgr update`, or Framework's USB updater). Set the battery charge limit (e.g. 80%) in the BIOS or with `framework_tool --charge-limit 80` (the bootstrap installs `framework-system` on Framework hardware): useful when the laptop lives docked. The Framework 16 keyboard/input modules get a udev rule for VIA/`qmk_hid`. Intel models get `thermald`, media drivers and `sof-firmware`; AMD models the Radeon Vulkan driver.

Keep Wi-Fi passwords, SSH/GPG keys and tokens out of this repo. SSH keys live in Bitwarden: pull them from there on each machine (step 2), never copy them between machines or commit them.

## 2. Workstation bootstrap

```sh
git clone https://github.com/Gitznik/dotfiles.git ~/dotfiles   # SSH keys aren't on the machine yet
cd ~/dotfiles && git switch arch
arch/bootstrap.sh work            # or: private, or: work private
```

Apps come in three lists: `apps-shared.txt` (every machine), `apps-work.txt`, `apps-private.txt`. The profile you pass is remembered in `~/.config/dotfiles-profile`, so later reruns need no argument; passing profiles again replaces it.

**Real machines only (not the VM):** SSH keys stay in Bitwarden and are never written to disk. Log into the Bitwarden desktop app, enable Settings > SSH agent, and keep the keys as SSH key items. `~/.config/environment.d/ssh-agent.conf` points `SSH_AUTH_SOCK` at `~/.bitwarden-ssh-agent.sock` for every app and user service (takes effect after a reboot). Then switch the remote: `git -C ~/dotfiles remote set-url origin git@github.com:Gitznik/dotfiles.git`.

**Keyring:** the bootstrap pre-creates an unencrypted default keyring, so apps store logins without asking: auto-login never types a password (a protected keyring would prompt every boot), and the disk is already encrypted by LUKS.

**Updating:** `just update` (or the update icon left of the clock, shown when the dotfiles are behind GitHub): pulls the dotfiles, `yay -Syu` (snap-pac snapshots each transaction), reruns the bootstrap, `mise upgrade`, and lists firmware updates.

**Web apps:** `webapp add NAME URL [ICON_URL] [--profile work|private]` adds a Chromium app window with its own launcher entry (`SUPER+D`) and icon (looked up in dashboard-icons when not given), listed in `arch/webapps.txt`; commit that file to get it on every machine. `webapp list`, `webapp remove NAME`.

The bootstrap installs `packages-repo.txt` and `packages-aur.txt`, checks for conflicts with existing files, stows the shared and desktop packages, installs the greetd config, enables services and sets zsh as the login shell. If any file would be overwritten, it stops before changing anything. Rerunning it is safe.

AUR packages (`packages-aur.txt`: walker, elephant and its providers, ttfx, zen-browser) are installed with yay, which the bootstrap installs first if missing. PKGBUILDs are not reviewed; the list prefers `-bin` packages that repackage upstream release binaries.

Reboot. After the LUKS passphrase, greetd logs you straight into Hyprland (via uwsm). After logging out, tuigreet asks for your password.

## 3. VM test loop

The VM needs a virtio GPU with 3D/GL acceleration, or Hyprland won't start. `just vm …` (`arch/vm/vm.sh`, needs `qemu-desktop edk2-ovmf`) provides this. Images live in `~/vms` (on btrfs: `chattr +C ~/vms` before creating them). The VM window grabs the keyboard while the pointer is over it (`grab-on-hover`), so `SUPER` bindings go to the guest. Don't press `Ctrl+Alt+G`: a full grab locks the pointer and the absolute USB tablet stops moving until you press it again.

1. Install base Arch (step 1) with `just vm iso` then `just vm create`, then snapshot it as **clean-base** with `just vm seal`. Restore it with `just vm reset`; boot with `just vm run`.
2. Run step 2 from the branch.
3. Run the checks below. Fix problems **in the repo** (push, then pull in the guest), not by hand in the guest.
4. Reboot, rerun `arch/bootstrap.sh`: no errors, nothing duplicated, no config overwritten.
5. Restore **clean-base**, repeat step 2 and pass the checks with no manual fixes.
6. Record the result: `git rev-parse --short HEAD` and `pacman -Q hyprland uwsm ghostty walker-bin elephant-bin waybar`.

### Milestone 1 checks

- [ ] LUKS prompt shows the Gitznik Plymouth theme (Catppuccin Mocha, lock icon, password box); a wrong passphrase re-prompts
- [ ] Boot: LUKS passphrase, then straight into Hyprland (no second password). Contour-line wallpaper, Catppuccin borders, no Hyprland logo or splash
- [ ] Log out: tuigreet appears in Catppuccin colors (mauve border, date and time on top, `*` while typing the password), and logging back in works
- [ ] `SUPER+RETURN` opens Ghostty (Catppuccin Mocha) with zsh, prompt and plugins and no startup errors; `tmux` starts
- [ ] `SUPER+D` opens walker and launches apps; `systemctl --user status elephant walker` shows both running
- [ ] `SUPER+HJKL` focus, `SUPER+SHIFT+HJKL` swap, `SUPER+S` toggle split, `SUPER+T` float, `SUPER+F` fullscreen with no border, `SUPER+W` close
- [ ] `SUPER+1…0` / `SUPER+SHIFT+1…0` switch and move windows across workspaces
- [ ] `SUPER+SHIFT+ESCAPE` leaves the session cleanly
- [ ] `hyprctl configerrors` is empty
- [ ] Idle: screensaver at 150s (fullscreen ttfx text effects on black, own special workspace, tiled layout untouched); a key press or mouse move closes it and restores the cursor
  - **Open (2026-11-27):** fails in the VM (Hyprland 0.57.2): every new window resets idle, so the screensaver window triggers hypridle's resume, which kills it, and the 300s lock is never reached. Plain windows reproduce it; hiding the cursor doesn't. Unknown whether it's Hyprland or QEMU's absolute tablet. Verify on hardware first
- [ ] Lock: `SUPER+CTRL+L` locks (Catppuccin swaylock over the blurred wallpaper, ring always visible); idle locks at 300s over the screensaver, display turns off at 330s, a key press wakes it to the lock screen
- [ ] Suspend (`systemctl suspend`) locks first; on resume the lock screen shows, never the unlocked desktop
- [ ] Locker robustness (hardware first; hyprlock crashed here when the display turned off while locked, see hyprwm/hyprlock#953): lock, then 10× `hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'` / `enable` from another TTY: swaylock survives. Then `pkill -9 swaylock`: the session **stays locked** (Hyprland's "lockscreen died" screen), and `swaylock` started from a TTY with `WAYLAND_DISPLAY` set takes over and unlocks normally

### Milestone 2 checks (bar and quick controls)

- [ ] Waybar starts with the session (`systemctl --user status waybar`): workspaces left, stay-awake / DND / clock center, tray / Bluetooth / network / audio / battery / power right. Catppuccin colors; Nerd Font icons render (no boxes)
- [ ] Clock shows date, time and UTC offset (e.g. `UTC+0100`); hovering shows a month calendar
- [ ] Workspace buttons follow `SUPER+1…0` and switch on click
- [ ] Bluetooth icon: click opens `bluetui` as a centered floating window; clicking again focuses it instead of opening a second one. Pair/connect a device (hardware)
- [ ] Network icon: click opens `nmtui connect`; switching Wi-Fi works (hardware; the VM only has ethernet)
- [ ] Audio icon: click opens `wiremix`, scroll changes volume, right-click mutes (icon dims)
- [ ] Battery shows on laptops, is hidden in the VM
- [ ] `SUPER+ESCAPE` and the power icon open the System menu; typing `lock`/`suspend` in `SUPER+D` finds the same entries. Lock, log out and reboot work from it

### Milestone 3 checks (screenshots and clipboard)

- [ ] `PRINT`: drag a region, or click a window to select it; `PRINT` again or Esc while selecting cancels
- [ ] satty opens floating and centered with the shot; arrow tool active, Catppuccin palette; draw, add text, blur
- [ ] Enter: annotated image is on the clipboard (paste into another app) **and** saved to `~/Pictures/Screenshots/`; satty closes
- [ ] Esc in satty discards: nothing saved, clipboard unchanged
- [ ] `SUPER+CTRL+V` opens the clipboard history in walker; copy 3 text items, pick the 2nd, `Ctrl+V` pastes it; a screenshot shows up as an image entry

### Milestone 4 checks (notifications, stay awake)

- [ ] `notify-send test hello` shows a Catppuccin toast top right, below the bar; clicking dismisses it; `notify-send -u critical x y` stays until clicked (peach border)
- [ ] Bell in the bar: click toggles do not disturb (bell turns peach and crossed out); while on, `notify-send` shows nothing; `makoctl restore` brings back the last one after turning it off
- [ ] Screen share (hardware, or VM if the portal works): start a portal screen share, e.g. in the browser; DND turns on by itself within ~2s, and turns off when the share stops. If DND was already on before sharing, it stays on afterwards
- [ ] `sleep 300 & kill -SEGV $!`: a critical "sleep crashed" toast appears; clicking it opens `coredumpctl info` in Ghostty. A second crash of the same program within 60s is not announced
- [ ] `systemctl --user status dnd-on-screenshare crash-watch` both running
- [ ] Coffee cup in the bar: click turns on stay awake (cup fills, peach); `journalctl --user -u hypridle` logs "systemd idle inhibit active" and no screensaver/lock/display-off happens past 330s; click again turns it off and idle works as before. `systemctl suspend` still locks first while it's on

### Dark mode checks

- [ ] `nautilus` and its file dialogs are dark (adw-gtk3-dark / libadwaita dark); `gsettings get org.gnome.desktop.interface color-scheme` is `'prefer-dark'`
- [ ] `qt6ct` opens in the Catppuccin palette (mauve selection); Qt apps follow it
- [ ] Same Adwaita cursor over windows, the bar and the desktop

### Apps and desktop plumbing checks

- [ ] `cat ~/.config/dotfiles-profile` shows the profile; apps from `apps-shared.txt` and that profile launch from `SUPER+D`
- [ ] Volume keys show the Catppuccin OSD and repeat while held; mute, mic mute, play/pause/next work, also on the lock screen. Brightness keys on laptops
- [ ] `SUPER+D` then `12*7`: the calculator result appears
- [ ] Links open in Zen; a PDF, image, video and folder open in Papers, imv, mpv, Nautilus (`xdg-open`)
- [ ] `sudo ufw status`: active, deny incoming, 53317 allowed (and 22 limited where sshd is enabled); LocalSend sees another device (hardware)
- [ ] `docker run --rm hello-world` works without sudo after re-login
- [ ] Element/Chromium login survives a reboot (keyring with an empty password)
- [ ] `ssh-add -l` lists the keys from Bitwarden's agent (real machines)

### System, hardware and update checks

- [ ] `snapper -c root list` shows pre/post pairs after a `yay` install; with Limine, the boot menu has a Snapshots entry, and booting one works (the VM uses Limine too)
- [ ] `zramctl` shows zram swap; `sysctl fs.inotify.max_user_watches` is 524288; `ulimit -n` in a terminal is 65536 (user session and system services)
- [ ] 3 wrong passwords on the lock screen don't lock the account for 10 minutes (`faillock` allows 10, unlocks after 2 min)
- [ ] `avahi-browse -at` lists network services; a network printer shows up in `system-config-printer` (hardware)
- [ ] `docker run --rm alpine nslookup archlinux.org` resolves with ufw active
- [ ] Docked with the lid closed: the laptop panel is off (`hyprctl monitors all` shows it disabled), workspaces and cursor stay on the external display; opening the lid turns it back on; booting with the lid closed starts on the external display only (hardware)
- [ ] `just update` runs through; the update icon appears when the dotfiles are behind and disappears after updating
- [ ] Deezer opens from `SUPER+D` as its own app window with its icon; `webapp add Test https://example.com` adds an entry right away, `webapp remove Test` removes it
- [ ] Framework: `framework_tool --power` reports battery/charger; Wi-Fi regulatory domain set (`iw reg get`) (hardware)

### Backup checks

- [ ] Bar shows the backup icon (peach) until `backup init` is done; after a first `backup run` it disappears. `backup init` works with an rclone remote (SMB to the Synology)
- [ ] `backup status` shows the target, last success and the timer; `backup restic snapshots` lists a snapshot per run
- [ ] `backup restic restore latest --target /tmp/r --include ~/Documents` restores files; a dir with `.nobackup` and the excludes (`~/.cache`, Trash, Downloads, …) aren't in the snapshot
- [ ] With the NAS unreachable, `backup run` skips with a message and exits 0; a failing run shows a critical notification and a red icon

### Later milestones (from the inventory)

1. Hardware: dock/lid, suspend/resume, second display (workspaces stay global), portal screen sharing

## Backups

`backup` (restic, through an rclone remote like everything else) backs up `~` daily (systemd user timer, catches up after the laptop was off) to the Synology, later also a Hetzner Storage Box: encrypted, deduplicated, kept 7 daily / 4 weekly / 12 monthly, checked weekly. Excludes: `~/.config/backup/excludes` (caches, Trash, Steam/Games, mise, Downloads, VMs, `node_modules`, `target/…`, `.venv`); put a `.nobackup` file in any other dir to skip it. Away from home the NAS isn't reachable and runs skip quietly. A bar icon appears when backups are failing, overdue (3 days) or not set up.

**Synology, once:** a shared folder `backup` (Btrfs volume) and a user `restic` with read/write on `backup` only and no other app permissions. SMB (Control Panel > File Services > SMB) must be on. Protect against a compromised laptop deleting backups: install Snapshot Replication (Package Center), then Snapshots > `backup` > Settings: daily schedule, **immutable** snapshots for at least 7 days (DSM 7.2+), retention ≥ that.

**Each machine, once:**

`backup init`: backend `rclone`, remote `robonas`. If the remote doesn't exist yet, it creates it (SMB: NAS host, user `restic`, password; rclone stores it obscured in `~/.config/rclone/rclone.conf`, keep it in Bitwarden too) and checks the connection. Path: `backup/restic/<host>`.

It stores the target only in `~/.config/backup/target.env` (never in this public repo), generates the repository password (keep the printed copy in **Bitwarden**: without it no restore on another machine) and stores it in the keyring, creates the repository and enables the timer. Then `backup run` (or the bar icon, or `just backup`). Plain SFTP with a dedicated key is still supported (`backend: sftp`), but needs the key installed on the NAS over admin SSH.

**Restore:** `backup restic snapshots`, `backup restic mount ~/mnt` (browse), `backup restic restore latest --target ~/restore --include ~/Documents`. On a new machine: same rclone remote, then `backup init` with the same path and the Bitwarden password.

**Hetzner Storage Box later:** another rclone remote (sftp or smb on the Storage Box) and a second repository; `backup` reads one target today, a second one is a small extension.

## Notes

- **Plymouth theme** (`arch/plymouth/gitznik`): adapted from Omarchy 4.5.0's theme (MIT, `LICENSE` alongside). To change the logo text, re-render `logo.png`:
  `magick -background none -fill '#cba6f7' +antialias -font JetBrainsMono-NF-Bold -pointsize 13 label:Gitznik -trim +repage -filter point -resize 1300% logo.png`
  (pixel style; for smooth letters, drop `+antialias … -resize 1300%` and use `-pointsize 170`). Then rerun the bootstrap.
- **Wallpaper** (`arch/stow/wallpaper`): generated, not downloaded. `arch/wallpaper/render.sh` (ImageMagick 7) renders the contour-line image and the blurred lock-screen copy at 5120x2880; `SEED=<n> arch/wallpaper/render.sh` gives different terrain.
