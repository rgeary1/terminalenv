#!/bin/bash

for f in $(ls -a dotfiles/.* dotfiles/bin/*); do
  if [[ ! -f $f ]]; then continue; fi
  dest=$HOME/$(basename $f)
  if [[ ! -f $dest ]]; then continue; fi
  echo "diff $f $dest"
  diff $f $dest
done

