#!/bin/bash

# fetch remote
git pull
echo Is updated?[y/N]
read opt

case $opt in
  y|Y)
    ;;
  *)
    echo quit
    exit 1
    ;;
esac

[ -f .vimrc ] && [ -f ~/.vimrc ] && cp .vimrc ~/.vimrc
[ -f .zshrc ] && [ -f ~/.zshrc ] && cp .zshrc ~/.zshrc
