# Omarchy machine (current daily driver)
stow-all:
  stow hyprland lazygit nvim omarchy tmux workmux zsh

# Plain Arch workstation: see arch/README.md
arch-bootstrap:
  arch/bootstrap.sh

# Plain Arch workstation: system packages, dotfiles + bootstrap, mise tools, firmware check
update:
  arch/update.sh

# Back up home now (restic; set up once with: backup init)
backup:
  ~/.local/bin/backup run

# Arch test VM: iso | create | install | seal | reset | run | ssh-key | ssh (see arch/vm/vm.sh)
[positional-arguments]
vm *args:
  arch/vm/vm.sh "$@"
