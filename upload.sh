#!/bin/bash

# Package dotfiles and commit tarball to the repo
set -euo pipefail
cd -- "$(dirname "$(readlink -f -- "$0")")"

GIT_SSH_CMD='ssh -i ~/.ssh/rgeary1'

# Build the tarball
./package.sh

# Commit the tarball
git add dotfiles.tar.gz dotfiles.tar.gz.SHA
git commit -m "Update dotfiles tarball" || echo "No tarball changes to commit"

# Push
echo "Pushing to GitHub..."
SSH_AGENT='' SSH_AUTH_SOCK='' GIT_SSH_COMMAND="$GIT_SSH_CMD" git push
