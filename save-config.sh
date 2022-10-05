#!/bin/bash

[ -f ~/.vimrc ] && cp ~/.vimrc .vimrc
[ -f ~/.zshrc ] && cp ~/.zshrc .zshrc

git add --all
git commit -m "update at [$(date +'%F %T')]"
