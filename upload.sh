#!/bin/bash

# Package dotfiles and upload as a GitHub release
set -euo pipefail
cd -- "$(dirname "$(readlink -f -- "$0")")"

REPO="rgeary1/terminalenv"
GIT_SSH_CMD='ssh -i ~/.ssh/rgeary1'

# Build the tarball
./package.sh

# Push any commits
echo "Pushing to GitHub..."
SSH_AGENT='' SSH_AUTH_SOCK='' GIT_SSH_COMMAND="$GIT_SSH_CMD" git push

# Create a release tag based on date
tag="v$(date +%Y%m%d-%H%M%S)"
git tag "$tag"
SSH_AGENT='' SSH_AUTH_SOCK='' GIT_SSH_COMMAND="$GIT_SSH_CMD" git push origin "$tag"

# Upload release with tarball
if command -v gh &>/dev/null; then
  gh release create "$tag" dotfiles.tar.gz dotfiles.tar.gz.SHA \
    --repo "$REPO" \
    --title "$tag" \
    --notes "Automated release of terminalenv dotfiles" \
    --latest
else
  # Fallback: create release via GitHub API
  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "ERROR: gh CLI not found and GITHUB_TOKEN not set."
    echo "Install gh (https://cli.github.com) or export GITHUB_TOKEN to upload the release."
    echo ""
    echo "Tag $tag has been pushed. You can manually create a release at:"
    echo "  https://github.com/$REPO/releases/new?tag=$tag"
    exit 1
  fi

  echo "Creating release via API..."
  response=$(curl -sf \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -d "{\"tag_name\":\"$tag\",\"name\":\"$tag\",\"body\":\"Automated release of terminalenv dotfiles\",\"make_latest\":\"true\"}" \
    "https://api.github.com/repos/$REPO/releases")

  upload_url=$(echo "$response" | grep -o '"upload_url":"[^"]*' | head -1 | sed 's/"upload_url":"//' | sed 's/{.*//')

  for asset in dotfiles.tar.gz dotfiles.tar.gz.SHA; do
    echo "Uploading $asset..."
    curl -sf \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Content-Type: application/octet-stream" \
      --data-binary "@$asset" \
      "${upload_url}?name=$asset"
  done
fi

echo ""
echo "Released $tag"
echo "  https://github.com/$REPO/releases/tag/$tag"
