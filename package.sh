#!/bin/bash

# Package dotfiles into a tarball for distribution via GitHub releases
set -euo pipefail
cd -- "$(dirname "$(readlink -f -- "$0")")"

outfile="dotfiles.tar.gz"

# Record symlinks so update.sh's per-file fallback can recreate them
# (GitHub raw serves a symlink as a file containing its target path)
(cd dotfiles && find . -type l -printf '%P %l\n' | sort) > dotfiles/symlinks

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
date -u +%Y-%m-%dT%H:%M:%SZ > "$tmpdir/.tarball_created"

tar -czf "$outfile" -C dotfiles . -C "$tmpdir" .tarball_created
sha256sum "$outfile" > "${outfile}.SHA"

echo "Created $outfile ($(du -h "$outfile" | cut -f1))"
echo "SHA256: $(cat "${outfile}.SHA")"
