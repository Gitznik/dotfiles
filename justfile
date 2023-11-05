install_config_files:
	for file in `ls .config`; do \
		ln -s ~/dotfiles/.config/$file ~/.config/$file; \
	done

install_mac: install_config_files
	ln -s ~/dotfiles/.skhdrc ~/
	ln -s ~/dotfiles/.yabairc ~/
