#!/bin/bash

./sync.zsh save

git add --all

if [ -z "$1" ]; then
    echo "please commit manually"
else
    if [[ "ts" == "$1" ]]; then
        git commit -m "update at [$(date +'%F %T')]"
    else
        git commit -m "$1"
    fi
fi
