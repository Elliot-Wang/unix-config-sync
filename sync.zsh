#!/bin/zsh

# 必须两边存在文件才会进行更新
config_file=( \
 ~/.vimrc .vimrc \
 ~/.zshrc .zshrc \
 ~/.config/neofetch/config.conf neofetch \
 ~/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/git/git.plugin.zsh zsh/git.plugin.zsh
)

# Darwin
mac_config_file=( \
 ~/.zsh/alter.zsh ./.zsh/alter.zsh.mac 
)

function save() {
    len=${#config_file[@]}
    declare -i i=0

    while [ "$len" -gt "$((2*i))" ]; do
        # zsh arr index start at 1
        sour="${config_file[i*2+1]}"
        dest="${config_file[i*2+2]}"
        copy $sour $dest

        ((i++))
    done
}


function update() {
    len=${#config_file[@]}
    declare -i i=0

    while [ "$len" -gt "$((2*i))" ]; do
        # zsh arr index start at 1
        sour="${config_file[i*2+1]}"
        dest="${config_file[i*2+2]}"
        copy $dest $sour

        ((i++))
    done
}

function copy() {
    if [ -f $1 ] && [ -f $2 ]; then
        cmp --silent $1 $2
        if [ ! $? -eq 0 ]; then
            echo "update $2 [y/N]"
            read opt

            case $opt in
                y|Y)
                    cp $1 $2
                    ;;
                *)
                    ;;
            esac
        fi
    fi
}


if [ "$1" ]; then
    if [[ "save" == "$1" ]]; then
        echo "save config"
        save
    elif [[ "update" == "$1" ]]; then
        echo "update config"
        update
    fi
fi
