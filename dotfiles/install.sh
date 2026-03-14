#!/bin/bash

set -euo pipefail
cd -- $(dirname $(readlink -f -- "$0"))
dryrun=0
mkdir -p $HOME/tmp
  
export SRC_URL=${SRC_URL-https://raw.githubusercontent.com/rgeary1/terminalenv/refs/heads/master}

if [[ "$0" == "-n" ]]; then
  echo "Dryrun mode"
  dryrun=1
fi

# Validation
if [[ ! -d ${HOME:?} || ! -w $HOME ]]; then
    echo 'No writeable $HOME'
    exit 1
fi
export DESTDIR=${DESTDIR-$HOME}

# Make dirs
echo "Installing to $DESTDIR"
mkdir -p ${DESTDIR}/bin

# Check for locally modified files before overwriting
CHECKSUM_FILE="${DESTDIR}/.dotfiles/.installed_checksums"
if [[ -f "$CHECKSUM_FILE" && $dryrun == 0 ]]; then
  modified_files=()
  while IFS='  ' read -r saved_sum fpath; do
    dest="${DESTDIR}/${fpath}"
    if [[ -f "$dest" ]]; then
      current_sum=$(md5sum "$dest" | cut -d' ' -f1)
      if [[ "$current_sum" != "$saved_sum" ]]; then
        modified_files+=("$fpath")
      fi
    fi
  done < "$CHECKSUM_FILE"

  if [[ ${#modified_files[@]} -gt 0 ]]; then
    echo "WARNING: The following files have been locally modified:"
    for mf in "${modified_files[@]}"; do
      echo "  $mf"
    done
    read -p "Overwrite these files? [y/N] " answer
    if [[ ! "$answer" =~ ^[Yy] ]]; then
      echo "Aborted."
      exit 0
    fi
  fi
fi

# Copy files
for f in $(cat filelist); do
  echo cp $f ${DESTDIR}/$f
  if [[ $dryrun == 0 ]]; then
    cp $f ${DESTDIR}/$f
  fi
done

# Save checksums of installed files
if [[ $dryrun == 0 ]]; then
  mkdir -p "${DESTDIR}/.dotfiles"
  > "$CHECKSUM_FILE"
  for f in $(cat filelist); do
    if [[ -f "${DESTDIR}/$f" ]]; then
      md5sum "${DESTDIR}/$f" | sed "s|${DESTDIR}/||" >> "$CHECKSUM_FILE"
    fi
  done
fi

# Modify files
[ ! -e $DESTDIR/.bashrc ] && touch $DESTDIR/.bashrc
grep -q 'source ~/.bashrc2' $DESTDIR/.bashrc || echo 'source ~/.bashrc2' >> $DESTDIR/.bashrc
chmod -R +x $DESTDIR/bin/

# Install missing packages
if which mosh >/dev/null 2>&1; then
  echo "mosh installed"
else
  echo "Installing mosh..."
  which yum >/dev/null 2>&1 && \
    sudo yum install -y protobuf-devel ncurses-devel zlib-devel openssl-devel libutempter-devel perl-diagnostics g++ git
  which apt-get >/dev/null 2>&1 && \
    sudo apt-get install -y libprotoc-dev libncurses5-dev zlib1g-dev libssl-dev libutempter-dev g++ protobuf-compiler git curl make build-essential pkg-config 
  ver=mosh-1.4.0
  f=mosh-1.4.0.tar.gz
  curl -s -L $SRC_URL/pkgs/$f -o $DESTDIR/tmp/$f
  curl -s -L $SRC_URL/pkgs/${f}.SHA -o $DESTDIR/tmp/${f}.SHA
  (cd $DESTDIR/tmp;
    sha256sum -c ${f}.SHA
    tar -C $DESTDIR/tmp -xf $f
    cd $ver
    ./configure
    make
    sudo make install
  )
  rm -rf $DESTDIR/tmp/*
fi

# Installing tmux plugin manager
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "Done.  Run :"
if [[ $SHELL =~ zsh ]]; then
    echo "  source ${DESTDIR/$HOME/~}/.zshrc"
elif [[ $SHELL =~ bash ]]; then
    echo "  source ${DESTDIR/$HOME/~}/.bashrc"
else
    echo "  ERROR: Unknown shell $SHELL"
fi

