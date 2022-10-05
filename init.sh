#!/bin/bash

# 确认系统发行版本
os_name="unknown"
test -f /etc/redhat-release && os_name="redhat"
test -f /etc/debian_version && os_name="debian"

# vim篇
if ! which vim; then
    echo "No Vim installed..."
    case $os_name in
      redhat)
        sudo yum install -y vim
        ;;
     debian)
       sudo apt install vim
       ;;
     unkown)
       echo Unkown Os
       ;;
    esac
fi
# 使用vim-plug管理插件
[ -f ~/.vim/autoload/plug.vim ] || mkdir -p ~/.vim/autoload && cp vim/plug.vim ~/.vim/autoload/plug.vim
cp .vimrc ~/.vimrc

# zsh篇
if ! which zsh; then
    echo "No zsh installed..."
    case $os_name in
      redhat)
        sudo yum install -y zsh
        ;;
     debian)
       sudo apt install zsh
       ;;
     unkown)
       echo Unkown Os
       exit 1
       ;;
    esac
fi
# 使用antigen管理插件
[ -f ~/.antigen/antigen.zsh ] || mkdir -p ~/.antigen && cp zsh/antigen.zsh ~/.antigen
cp .zshrc ~/.zshrc
