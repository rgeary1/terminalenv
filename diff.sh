#!/bin/bash

num_diffs=0
for f in $(ls -a dotfiles/.* dotfiles/bin/*); do
  if [[ ! -f $f ]]; then continue; fi
  dest=$HOME/$(basename $f)
  if [[ ! -f $dest ]]; then continue; fi
  if ! diff -q $f $dest >/dev/null; then
    echo "diff "$@" $f $dest"
    diff "$@" $f $dest
    num_diffs=$(($num_diffs+1))
  fi
done

echo "$num_diffs file different"

