# Omarchy machine (current daily driver)
stow-all:
  stow hyprland lazygit nvim omarchy tmux workmux zsh

# Plain Arch workstation: see arch/README.md
arch-bootstrap:
  arch/bootstrap.sh

# Plain Arch workstation: system packages, dotfiles + bootstrap, mise tools, firmware check
update:
  arch/update.sh

# Arch test VM: iso | create | install | seal | reset | run | ssh-key | ssh (see arch/vm/vm.sh)
[positional-arguments]
vm *args:
  arch/vm/vm.sh "$@"
