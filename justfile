# Omarchy machine (current daily driver)
stow-all:
  stow hyprland lazygit nvim omarchy tmux workmux zsh

# Plain Arch workstation: see arch/README.md
arch-bootstrap:
  arch/bootstrap.sh

# Arch test VM: iso | create | install | seal | reset | run (see arch/vm/vm.sh)
vm *args:
  arch/vm/vm.sh {{args}}
