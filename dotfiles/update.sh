#!/bin/bash

export RELEASE_URL=${RELEASE_URL-https://github.com/rgeary1/terminalenv/releases/latest/download}
export SRC_URL=${SRC_URL-https://raw.githubusercontent.com/rgeary1/terminalenv/refs/heads/master}

set -eu

# Validation
if [[ ! -d $HOME || ! -w $HOME ]]; then
    echo 'No writeable $HOME'
    exit 1
fi
export SRCDIR="${SRCDIR-$HOME}/.dotfiles"

echo "Updating to $SRCDIR"
mkdir -p "$SRCDIR"

# Try downloading the tarball from GitHub releases first
tarball="$SRCDIR/dotfiles.tar.gz"
if curl -sfL "$RELEASE_URL/dotfiles.tar.gz" -o "$tarball"; then
  echo "Extracting dotfiles.tar.gz"
  tar -xzf "$tarball" -C "$SRCDIR"
  rm -f "$tarball"
else
  # Fallback: download files individually from raw GitHub
  echo "No release tarball found, falling back to individual file downloads"
  for f in filelist install.sh diff.sh update.sh; do
    echo "curl -s $SRC_URL/dotfiles/$f -o $SRCDIR/$f"
    curl -s "$SRC_URL/dotfiles/$f" -o "$SRCDIR/$f"
  done

  for f in $(cat $SRCDIR/filelist); do
    dir=$(dirname "$f")
    mkdir -p "$SRCDIR/$dir"
    echo curl -s $SRC_URL/dotfiles/$f -o "$SRCDIR/$f"
    curl -s $SRC_URL/dotfiles/$f -o "$SRCDIR/$f" || echo "Failed to copy $f"
  done
fi

chmod +x "$SRCDIR/update.sh" "$SRCDIR/install.sh" "$SRCDIR/diff.sh"

# Install the files
"$SRCDIR/install.sh"
