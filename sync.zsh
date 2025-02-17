#!/bin/zsh

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

function copy_list() {
    setopt localoptions noglob  # 禁用模式匹配
    cmd=$1
    len=$#

    my_array=(${@})
    declare -i i=0

    while [ "$len" -gt "$((2*i+1))" ]; do
        # zsh arr index start at 1
        first="${my_array[i*2+2]}"
        second="${my_array[i*2+3]}"
        if [[ $cmd == "save" ]]; then
            copy $first $second
        elif [[ $cmd == "update" ]]; then
            copy $second $first
        elif [[ $cmd == "debug" ]]; then
            echo copy $first $second
        elif [[ $cmd == "CMD_diff" ]]; then
            which delta > /dev/null 2>&1 && delta --features side-by-side $first $second \
                || git diff --no-index $first $second
        else
            echo "unknow cmd"
            exit 1
        fi

        ((i++))
    done
}


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

if [ "$1" ]; then
    # 确认系统发行版本
    os_name=$(uname)
    if [[ "save" == "$1" ]]; then
        echo "save config"
        copy_list save ${config_file[@]}
        if [[ "$os_name" == "Darwin" ]]; then
            copy_list save ${mac_config_file[@]}
        fi
    elif [[ "update" == "$1" ]]; then
        echo "update config"
        copy_list update ${config_file[@]}
        if [[ "$os_name" == "Darwin" ]]; then
            copy_list update ${mac_config_file[@]}
        fi
    elif [[ "debug" == "$1" ]]; then
        echo "debug config"
        copy_list debug ${config_file[@]}
        if [[ "$os_name" == "Darwin" ]]; then
            copy_list debug ${mac_config_file[@]}
        fi
    elif [[ "diff" == "$1" ]]; then
        echo "diff config"
        copy_list CMD_diff ${config_file[@]}
        if [[ "$os_name" == "Darwin" ]]; then
            copy_list diff ${mac_config_file[@]}
        fi
    fi
fi
