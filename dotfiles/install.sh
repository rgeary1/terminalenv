#!/bin/bash

set -euo pipefail
cd -- $(dirname $(readlink -f -- "$0"))
dryrun=0

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

# Copy files
for f in $(cat filelist); do
  echo cp $f ${DESTDIR}/$f
  if [[ $dryrun == 0 ]]; then
    cp $f ${DESTDIR}/$f
  fi
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
  which yum >/dev/null 2>&1 && \
    sudo yum install -y protobuf-devel ncurses-devel zlib-devel openssl-devel libutempter-devel
  which apt-get >/dev/null 2>&1 && \
    sudo apt-get install -y libprotoc-dev libncurses5-dev zlib1g-dev libssl-dev libutempter-dev
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

