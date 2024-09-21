#!/bin/bash
 
export SRC_URL=${SRC_URL-https://raw.githubusercontent.com/rgeary1/terminalenv/main}

set -eu

# Validation
if [[ ! -d $HOME || ! -w $HOME ]]; then
    echo 'No writeable $HOME'
    exit 1
fi
export SRCDIR="${SRCDIR-$HOME}/.dotfiles"

echo "Copying to $SRCDIR"
mkdir -p "$SRCDIR"

for f in filelist install.sh diff.sh; do
  echo "curl -s $SRC_URL/dotfiles/$f -o $SRCDIR/$f"
  curl -s "$SRC_URL/dotfiles/$f" -o "$SRCDIR/$f"
done
chmod +x "$SRCDIR/install.sh"
chmod +x "$SRCDIR/diff.sh"

# Copy the files
for f in $(cat $SRCDIR/filelist); do
  dir=$(dirname "$f")
  mkdir -p "$SRCDIR/$dir"
  echo curl -s $SRC_URL/dotfiles/$f -o "$SRCDIR/$f"
  curl -s $SRC_URL/dotfiles/$f -o "$SRCDIR/$f" || echo "Failed to copy $f"
done

# Install the files
"$SRCDIR/install.sh"

