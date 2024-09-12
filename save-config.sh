#!/bin/bash

[ -f ~/.vimrc ] && cp ~/.vimrc .vimrc
[ -f ~/.zshrc ] && cp ~/.zshrc .zshrc
[ -f ~/.config/neofetch/config.conf ] && cp ~/.config/neofetch/config.conf neofetch

# 确认系统发行版本
os_name=$(uname)
if [[ "$os_name" == "Darwin" ]]; then
    [ -f  ~/.zsh/alter.zsh ] && cp ~/.zsh/alter.zsh ./.zsh/alter.zsh.mac 
fi

git add --all
if [ -z "$1" ]; then
    git commit -m "update at [$(date +'%F %T')]"
else
    git commit -m "$1"
fi
