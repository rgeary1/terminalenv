#!/bin/bash

diff_flags=""
update=0

if [[ $1 == "-q" ]]; then
  diff_flags="-q"
fi
if [[ $1 == "-u" ]]; then
  update=1
fi

cd dotfiles
num_diffs=0
for f in $(cat filelist); do
  dest="$HOME/$f"
  if [[ ! -f $f ]]; then echo "Missing $f; cp $dest $PWD/$f"; continue; fi
  if [[ ! -f $dest ]]; then echo "Missing $dest"; continue; fi
  if ! diff -q $f $dest >/dev/null; then
    if [[ $update == 0 ]]; then
      echo "diff "$@" $f $dest"
      diff $diff_flags --color "$@" $f $dest
    else
      echo "cp $dest $f"
      cp "$dest" "$f"
    fi
    num_diffs=$(($num_diffs+1))
  fi
done

if [[ $update == 0 ]]; then
  echo
  echo "$num_diffs file(s) different.  Run with '-u' to update."
else
  echo "$num_diffs file(s) updated"
fi

