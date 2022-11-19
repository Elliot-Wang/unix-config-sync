#!/bin/bash

[ -f ~/.vimrc ] && cp ~/.vimrc .vimrc
[ -f ~/.zshrc ] && cp ~/.zshrc .zshrc
[ -f ~/.config/neofetch/config.conf ] && cp ~/.config/neofetch/config.conf neofetch

git add --all
git commit -m "update at [$(date +'%F %T')]"
