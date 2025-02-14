#!/bin/bash

export SRC_URL=${SRC_URL-https://raw.githubusercontent.com/rgeary1/terminalenv/refs/heads/master}

set -eu

DOTFILES=$HOME/.dotfiles
mkdir -p $DOTFILES
curl -s -L $SRC_URL/dotfiles/update.sh -o $DOTFILES/update.sh

bash $DOTFILES/update.sh

