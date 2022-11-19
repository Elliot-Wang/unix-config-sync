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
