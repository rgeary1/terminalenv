#!/bin/bash

set -euo pipefail

cd -- $(dirname $(readlink -f -- "$0"))

DESTDIR=${DESTDIR-${HOME?}}

rv=0
for f in $(cat filelist); do
  if ! diff -q "$f" "$DESTDIR/$f" 2>/dev/null; then
    echo "> diff --color -U3 $f $DESTDIR/$f"
    diff --color -U3 "$f" "$DESTDIR/$f" || rv=1
    echo
  fi
done
exit $rv
