#!/bin/bash

# 确认系统发行版本
os_name="unknown"
test -f /etc/redhat-release && os_name="redhat"
test -f /etc/debian_version && os_name="debian"

# vim篇
if ! which vim > /etc/null; then
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
        exit 1
        ;;
    esac
fi
# 使用vim-plug管理插件
[ -f ~/.vim/autoload/plug.vim ] || mkdir -p ~/.vim/autoload && cp vim/plug.vim ~/.vim/autoload/plug.vim
# onedark.vim
cp -r vim/onedark.vim/* ~/.vim
cp .vimrc ~/.vimrc
# dnf and nodejs
case $os_name in
    redhat)
        sudo yum install -y dnf
        sudo dnf install -y nodejs npm
        sudo dnf -y install https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm
        sudo dnf upgrade -y git
        ;;
    debian)
        sudo apt install nodejs
        ;;
    unkown)
        ;;
esac

# zsh篇
if ! which zsh > /etc/null; then
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

# neofetch篇
if ! which neofetch > /etc/null; then
    echo "No neofetch installed..."
    case $os_name in
      redhat)
        curl -o /etc/yum.repos.d/konimex-neofetch-epel-7.repo \
            https://copr.fedorainfracloud.org/coprs/konimex/neofetch/repo/epel-7/konimex-neofetch-epel-7.repo
        sudo yum install -y neofetch
        ;;
      debian)
        sudo apt install neofetch
        ;;
      unkown)
        echo Unkown Os
        exit 1
        ;;
    esac
fi
# neofetch配置文件
[ -f ~/.config/neofetch/config.conf ] || mkdir -p ~/.config/neofetch && cp neofetch/config.conf ~/.config/neofetch
