#!/bin/bash

# 确认系统发行版本
os_name=$(uname)
test -f /etc/redhat-release && os_name="redhat"
test -f /etc/debian_version && os_name="debian"

# vim篇
if ! which vim > /dev/null 2>&1; then
    echo "No Vim installed..."
    case $os_name in
      redhat)
        sudo yum install -y vim
        ;;
      debian)
        sudo apt install vim
        ;;
      * )
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
# disable coc at start
sed -i 's/enableCoc = 1/enableCoc = 0/' ~/.vimrc
# dnf and nodejs
case $os_name in
    redhat)
        sudo yum install -y dnf
        sudo dnf install -y nodejs npm
	sudo dnf install -y zsh
        #sudo dnf -y install https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm
        sudo dnf upgrade -y git
        ;;
    debian)
        sudo apt install nodejs
        ;;
    Darwin)
        # it depende on
        ;;
esac

# zsh篇
# chsh -s $(which zsh)
if ! which zsh > /dev/null 2>&1; then
    echo "No zsh installed..."
    case $os_name in
      redhat)
       sudo yum install -y zsh
       ;;
      debian)
        sudo apt install zsh
        ;;
      * )
        echo Unkown Os
        exit 1
        ;;
    esac
fi
# 使用antigen管理插件
[ -f ~/.antigen/antigen.zsh ] || mkdir -p ~/.antigen && cp zsh/antigen.zsh ~/.antigen
cp .zshrc ~/.zshrc
{ test -d ~/.zsh || mkdir ~/.zsh 2> /dev/null } && for file in .zsh/*.zsh; do cp $file ~/$file; done

# neofetch篇
if ! which neofetch > /dev/null 2>&1; then
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
      Darwin)
        brew install neofetch
        ;;
      * )
        echo Unkown Os
        exit 1
        ;;
    esac
fi

# neofetch配置文件
[ -f ~/.config/neofetch/config.conf ] || mkdir -p ~/.config/neofetch && cp neofetch/config.conf ~/.config/neofetch

# ranger
if ! which ranger > /dev/null 2>&1; then
    echo "No ranger installed..."
    case $os_name in
      redhat|debian|Darwin)
        pip3 install ranger-fm
        ranger --copy-config=rc
        ranger --copy-config=scope
        ;;
      * )
        echo Unkown Os
        exit 1
        ;;
    esac
fi

# optional
# fd, choose, duf, dust, htop, httpie...
opt=("")

# alter to native cmd
if [[ "$os_name" == "Darwin" ]]; then
    # no override config
    test -e ~/.zsh/alter.zsh || cp ./.zsh/alter.zsh.mac ~/.zsh/alter.zsh
    # cat alter
    if ! which bat > /dev/null 2>&1; then
        brew install bat
    fi
    # cd alter
    if ! which zoxide > /dev/null 2>&1; then
        brew install zoxide
    fi

    # install cargo
    if ! which cargo > /dev/null 2>&1; then
        brew install rust
    fi

    for element in "${arr[@]}"; do
        # ls alter
        if [[ "$element" == "exa" ]]; then
            if ! which exa > /dev/null 2>&1; then
                cargo install exa
            fi
        fi

        # diff alter
        if [[ "$element" == "delta" ]]; then
            if ! which delta > /dev/null 2>&1; then
                brew install git-delta
            fi
        fi
        # find alter
        if [[ "$element" == "fd" ]]; then
            if ! which fd > /dev/null 2>&1; then
                brew install fd
            fi
        fi
        # sed alter
        if [[ "$element" == "sd" ]]; then
            if ! which sd > /dev/null 2>&1; then
                cargo install sd
            fi
        fi
        # git grep alter
        if [[ "$element" == "ripgrep" ]]; then
            if ! which rg > /dev/null 2>&1; then
                brew install ripgrep
            fi
        fi
    done

fi

if [[ "$os_name" == "redhat" ]]; then
    for element in "${arr[@]}"; do

        # cd alter
        if [[ "$element" == "zoxide" ]]; then
            if ! which zoxide > /dev/null 2>&1; then
                dnf install zoxide
            fi
        fi

        # ls alter
        if [[ "$element" == "exa" ]]; then
            if ! which exa > /dev/null 2>&1; then
                echo "no implement install exa"
            fi
        fi

        # diff alter
        if [[ "$element" == "delta" ]]; then
            if ! which delta > /dev/null 2>&1; then
                echo "no implement install delta"
            fi
        fi
        # find alter
        if [[ "$element" == "fd" ]]; then
            if ! which fd > /dev/null 2>&1; then
                echo "no implement install fd"
            fi
        fi
        # sed alter
        if [[ "$element" == "sd" ]]; then
            if ! which sd > /dev/null 2>&1; then
                echo "no implement install sd"
            fi
        fi
        # git grep alter
        if [[ "$element" == "ripgrep" ]]; then
            if ! which rg > /dev/null 2>&1; then
                echo "no implement install ripgrep"
            fi
        fi
    done
fi
