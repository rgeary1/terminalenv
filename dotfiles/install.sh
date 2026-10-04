#!/bin/bash

set -euo pipefail
cd -- $(dirname $(readlink -f -- "$0"))
dryrun=0
assume_yes=0
skip_different=0

usage() {
  echo "Usage: $0 [-n] [-y|--assume-yes] [--skip-different]"
  echo "  -n                Dry run"
  echo "  -y, --assume-yes  Overwrite locally modified files without prompting"
  echo "  --skip-different  Leave locally modified files untouched, install the rest"
}

for arg in "$@"; do
  case $arg in
    -n) dryrun=1 ;;
    -y|--assume-yes) assume_yes=1 ;;
    --skip-different) skip_different=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg"; usage; exit 1 ;;
  esac
done
if [[ $dryrun == 1 ]]; then
  echo "Dryrun mode"
fi

mkdir -p $HOME/tmp

export SRC_URL=${SRC_URL-https://raw.githubusercontent.com/rgeary1/terminalenv/refs/heads/main}
export INSTALL_MOSH=${INSTALL_MOSH-0}

# Validation
if [[ ! -d ${HOME:?} || ! -w $HOME ]]; then
    echo 'No writeable $HOME'
    exit 1
fi
export DESTDIR="${DESTDIR-$HOME}"
export DOTFILES_DIR="$DESTDIR/.dotfiles"

# Make dirs
echo "Installing to $DESTDIR"
mkdir -p "${DESTDIR}/bin"

# Check for locally modified files before overwriting
CHECKSUM_FILE="${DOTFILES_DIR}/.installed_checksums"
skipped=" "
if [[ -f "$CHECKSUM_FILE" && $dryrun == 0 ]]; then
  modified_files=()
  while IFS='  ' read -r saved_sum fpath; do
    dest="${DESTDIR}/${fpath}"
    if [[ -f "$dest" ]]; then
      current_sum=$(md5sum "$dest" | cut -d' ' -f1)
      new_sum=$(md5sum "$DOTFILES_DIR/${fpath}" | cut -d' ' -f1)
      if [[ "$current_sum" != "$saved_sum" && "$current_sum" != "$new_sum" ]]; then
        modified_files+=("$fpath")
      fi
    fi
  done < "$CHECKSUM_FILE"

  if [[ ${#modified_files[@]} -gt 0 ]]; then
    echo "WARNING: The following files have been locally modified:"
    for mf in "${modified_files[@]}"; do
      current_sum=$([ -e "$DESTDIR/$mf" ] && md5sum "$DESTDIR/$mf" | cut -d' ' -f1)
      new_sum=$(md5sum "$DOTFILES_DIR/${mf}" | cut -d' ' -f1)
      echo "  $mf   current:$current_sum  new:$new_sum"
    done
    if [[ $skip_different == 1 ]]; then
      echo "Skipping these files (--skip-different)"
      skipped=" ${modified_files[*]} "
    elif [[ $assume_yes == 1 ]]; then
      echo "Overwriting these files (--assume-yes)"
    else
      # Prompt on the terminal, not stdin, so this works under `curl | bash`
      answer=""
      echo -n "Overwrite these files? [y/N] "
      if ! read -r answer 2>/dev/null </dev/tty; then
        echo
        echo "No terminal to prompt on. Re-run with -y or --skip-different."
        exit 1
      fi
      if [[ ! "$answer" =~ ^[Yy] ]]; then
        echo "Aborted."
        exit 0
      fi
    fi
  fi
fi

# Copy files
for f in $(cat filelist); do
  if [[ $skipped == *" $f "* ]]; then
    echo "skip $f (locally modified)"
    continue
  fi
  echo cp $f ${DESTDIR}/$f
  if [[ $dryrun == 0 ]]; then
    cp $f ${DESTDIR}/$f
  fi
done

# Remove old files
if [[ -e $DESTDIR/bin/jq ]]; then
  rm -f ${DESTDIR}/bin/jq
fi
# Rename old files
if [[ -e ${DESTDIR}/.bashrc2 ]]; then
  mv $DESTDIR/.bashrc2 $DESTDIR/.bashrc.local
fi

# Save checksums of installed files
if [[ $dryrun == 0 ]]; then
  mkdir -p "${DOTFILES_DIR}"
  old_checksums=$(cat "$CHECKSUM_FILE" 2>/dev/null || true)
  > "$CHECKSUM_FILE"
  for f in $(cat filelist); do
    if [[ $skipped == *" $f "* ]]; then
      # Keep the old checksum so the file is still flagged as modified next time
      awk -v f="$f" '$2 == f' <<<"$old_checksums" >> "$CHECKSUM_FILE"
    elif [[ -f "${DESTDIR}/$f" ]]; then
      md5sum "${DESTDIR}/$f" | sed "s|${DESTDIR}/||" >> "$CHECKSUM_FILE"
    fi
  done
fi

# Modify files
[ ! -e $DESTDIR/.bashrc ] && touch $DESTDIR/.bashrc
grep -q 'source ~/.bashrc.local' $DESTDIR/.bashrc || echo 'source ~/.bashrc.local' >> $DESTDIR/.bashrc
# Remove old ref
sed -i -e 's,^source ~/.bashrc2$,,' $DESTDIR/.bashrc
[ ! -e $DESTDIR/.zshrc ] && touch $DESTDIR/.zshrc
grep -q '.zshrc.local' $DESTDIR/.zshrc || echo '[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local' >> $DESTDIR/.zshrc
chmod -R +x $DESTDIR/bin/

# Daily auto-update cron job. Added once; any existing line mentioning
# .dotfiles/update.sh (including a commented-out one) is left alone, so
# commenting it out disables auto-update on this host.
if [[ $dryrun == 0 && $DESTDIR == "$HOME" ]] && which crontab >/dev/null 2>&1; then
  current_crontab=$(crontab -l 2>/dev/null || true)
  if ! grep -q '\.dotfiles/update\.sh' <<<"$current_crontab"; then
    echo "Adding daily update cron job"
    cron_line="0 0 * * * $HOME/.dotfiles/update.sh --skip-different > $HOME/.dotfiles/update.log 2>&1"
    if [[ -n $current_crontab ]]; then
      printf '%s\n%s\n' "$current_crontab" "$cron_line" | crontab -
    else
      echo "$cron_line" | crontab -
    fi
  fi
fi

# Install missing packages
if [[ $INSTALL_MOSH == 1 ]]; then
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

