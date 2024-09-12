#!/bin/bash

# fetch remote
git pull
echo Want to update configs? [y/N]
read opt

case $opt in
  y|Y)
    ;;
  *)
    echo Quit.
    exit 1
    ;;
esac

[ -f .vimrc ] && [ -f ~/.vimrc ] && cp .vimrc ~/.vimrc
[ -f .zshrc ] && [ -f ~/.zshrc ] && cp .zshrc ~/.zshrc
[ -f neofetch/config.conf ] && [ -f ~/.config/neofetch/config.conf ] && cp neofetch/config.conf ~/.config/neofetch/config.conf 

# 确认系统发行版本
os_name=$(uname)
if [[ "$os_name" == "Darwin" ]]; then
    [ -f  ./.zsh/alter.zsh.mac ] && [ -d  ~/.zsh ] && cp ./.zsh/alter.zsh.mac ~/.zsh/alter.zsh 
fi
