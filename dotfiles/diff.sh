#!/bin/bash

set -eu

quiet=0
if [[ ${1-} == "-q" ]]; then
  quiet=1
fi

cd -- $(dirname $(readlink -f -- "$0"))

DESTDIR=${DESTDIR-${HOME?}}

rv=0
for f in $(cat filelist); do
  # Symlinks: compare where they point, not the contents of the target
  if [[ -L $f || -L $DESTDIR/$f ]]; then
    if [[ -L $f && -L $DESTDIR/$f && $(readlink "$f") == "$(readlink "$DESTDIR/$f")" ]]; then continue; fi
    if [[ $quiet == 1 ]]; then
      echo "$f"
    else
      echo "> symlink differs: $f -> $(readlink "$f" || echo '<not a symlink>'); $DESTDIR/$f -> $(readlink "$DESTDIR/$f" || echo '<not a symlink>')"
      echo
    fi
    rv=1
    continue
  fi
  if [[ $quiet == 1 ]]; then
    if ! diff -q "$f" "$DESTDIR/$f" >/dev/null 2>&1; then
      echo "$f"
      rv=1
    fi
  elif ! diff -q "$f" "$DESTDIR/$f" 2>/dev/null; then
    echo "> diff --color -U3 $f $DESTDIR/$f"
    diff --color -U3 "$f" "$DESTDIR/$f" || rv=1
    echo
  fi
done
exit $rv
