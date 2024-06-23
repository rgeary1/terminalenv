#!/bin/bash
 
export SRC_URL=${SRC_URL-https://raw.githubusercontent.com/rgeary1/terminalenv/main}

set -eu

# Validation
if [[ ! -d $HOME || ! -w $HOME ]]; then
    echo 'No writeable $HOME'
    exit 1
fi
export DESTDIR=${DESTDIR-$HOME}
mode="copy"

echo "Installing to $DESTDIR"

# Set up directories
mkdir -p $DESTDIR/bin
mkdir -p $DESTDIR/bin/sbin
mkdir -p $DESTDIR/tmp

# Copy the files
files=(
    ".bashrc2"
    ".zshrc"
    ".tmux.conf"
    ".vimrc"
    ".shell_alias"
    ".git_alias"
    "bin/tmux-a"
    "bin/xgrep"
    "bin/sbin/aws_sleep_on_idle"
)
for f in ${files[@]}; do
    echo curl -s $SRC_URL/dotfiles/$f -o $DESTDIR/$f
    curl -s $SRC_URL/dotfiles/$f -o $DESTDIR/$f
done

# Modify files
[ ! -e $DESTDIR/.bashrc ] && touch $DESTDIR/.bashrc
grep -q 'source ~/.bashrc2' $DESTDIR/.bashrc || echo 'source ~/.bashrc2' >> $DESTDIR/.bashrc
chmod -R +x $DESTDIR/bin/

# Install missing packages
if which mosh >/dev/null 2>&1; then
  echo "mosh installed"
else
  echo "Installing mosh..."
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

echo "Done.  Run :"
if [[ $SHELL =~ zsh ]]; then
    echo "  source ${DESTDIR/$HOME/~}/.zshrc"
elif [[ $SHELL =~ bash ]]; then
    echo "  source ${DESTDIR/$HOME/~}/.bashrc"
else
    echo "  ERROR: Unknown shell $SHELL"
fi
