#!/bin/bash

# Package dotfiles into a tarball for distribution via GitHub releases
set -euo pipefail
cd -- "$(dirname "$(readlink -f -- "$0")")"

outfile="dotfiles.tar.gz"

tar -czf "$outfile" -C dotfiles .
sha256sum "$outfile" > "${outfile}.SHA"

echo "Created $outfile ($(du -h "$outfile" | cut -f1))"
echo "SHA256: $(cat "${outfile}.SHA")"
