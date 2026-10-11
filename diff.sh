#!/bin/bash

diff_flags=""
update=0

if [[ $1 == "-q" ]]; then
  diff_flags="-q"
fi
if [[ $1 == "-u" ]]; then
  update=1
fi

link_desc() {
  if [[ -L $1 ]]; then echo "-> $(readlink "$1")"
  elif [[ -e $1 ]]; then echo "(not a symlink)"
  else echo "(missing)"
  fi
}

cd dotfiles
num_diffs=0
for f in $(cat filelist); do
  dest="$HOME/$f"
  # Symlinks: compare where they point, not the contents of the target
  if [[ -L $f || -L $dest ]]; then
    if [[ -L $f && -L $dest && $(readlink "$f") == "$(readlink "$dest")" ]]; then continue; fi
    if [[ $update == 0 ]]; then
      echo "symlink differs: $f $(link_desc "$f"); $dest $(link_desc "$dest")"
    elif [[ ! -e $dest && ! -L $dest ]]; then
      echo "Missing $dest"; continue
    else
      echo "cp -P $dest $f"
      rm -f "$f"
      mkdir -p "$(dirname "$f")"
      cp -P "$dest" "$f"
    fi
    num_diffs=$(($num_diffs+1))
    continue
  fi
  if [[ ! -f $dest ]]; then echo "Missing $dest"; continue; fi
  # In filelist and on the host, but not yet in the repo
  if [[ ! -f $f ]]; then
    if [[ $update == 0 ]]; then
      echo "new on host: $dest (not in dotfiles/$f)"
      diff $diff_flags --color "$@" /dev/null $dest
    else
      echo "cp $dest $f"
      mkdir -p "$(dirname "$f")"
      cp "$dest" "$f"
    fi
    num_diffs=$(($num_diffs+1))
    continue
  fi
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

