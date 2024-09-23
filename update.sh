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
