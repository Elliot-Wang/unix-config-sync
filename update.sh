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

./sync.zsh update

# 确认系统发行版本
os_name=$(uname)
if [[ "$os_name" == "Darwin" ]]; then
    [ -f  ./.zsh/alter.zsh.mac ] && [ -d  ~/.zsh ] && cp ./.zsh/alter.zsh.mac ~/.zsh/alter.zsh 
fi
