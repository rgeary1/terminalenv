#!/bin/bash
 
export SRC_URL=${SRC_URL-https://raw.githubusercontent.com/rgeary1/terminalenv/main}

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

echo "Done.  Run :"
if [[ $SHELL =~ zsh ]]; then
    echo "  source ${DESTDIR/$HOME/~}/.zshrc"
elif [[ $SHELL =~ bash ]]; then
    echo "  source ${DESTDIR/$HOME/~}/.bashrc"
else
    echo "  ERROR: Unknown shell $SHELL"
fi
