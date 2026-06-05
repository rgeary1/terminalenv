#!/bin/bash

set -eu

BACKUP_SRC=${BACKUP_SRC-$HOME/qbm}

nowu=$(date +%s)
now=$(date -d@$nowu +%Y-%m-%dT%H.%M.%S)
HOSTS="localhost"
rflags="--exclude build --exclude builds --exclude target"

if [[ "$@" != "" ]]; then
  HOSTS="$@"
fi

# Choose a backup root OFF the home btrfs pool when available, else fall back to ~/.backup.
# (hardlink incrementals via --link-dest must stay on one filesystem, so the whole tree lives here)
BACKUP_ROOT=""
for cand in /opt/data1/backup /backup; do
  if mkdir -p "$cand" 2>/dev/null && [[ -w "$cand" ]]; then
    BACKUP_ROOT="$cand"
    break
  fi
done
BACKUP_ROOT=${BACKUP_ROOT:-$HOME/.backup}
echo "Using backup root: $BACKUP_ROOT"

for HOST in ${HOSTS}; do
  BACKUP_DIR=$BACKUP_ROOT/$HOST

  mkdir -p $BACKUP_DIR

  snapshot_name=snapshot.$now
  if [[ $HOST == localhost ]]; then
    echo "rsync -avPh --delete $rflags --link-dest=$BACKUP_DIR/current $BACKUP_SRC $BACKUP_DIR/$snapshot_name > $BACKUP_DIR/$HOST.log 2>&1"
    rsync -avPh --delete $rflags --link-dest=$BACKUP_DIR/current $BACKUP_SRC $BACKUP_DIR/$snapshot_name > $BACKUP_DIR/$HOST.log 2>&1
  else 
    echo "rsync -avPh --delete $rflags --link-dest=$BACKUP_DIR/current $HOST:$BACKUP_SRC $BACKUP_DIR/$snapshot_name > $BACKUP_DIR/$HOST.log 2>&1"
    rsync -avPh --delete $rflags --link-dest=$BACKUP_DIR/current $HOST:$BACKUP_SRC $BACKUP_DIR/$snapshot_name > $BACKUP_DIR/$HOST.log 2>&1
  fi

  if [[ $? == 0 ]]; then
    # Update symlink
    ln -nfs $BACKUP_DIR/$snapshot_name $BACKUP_DIR/current
  else
    # Rename dir if failed
    mv $BACKUP_DIR/$snapshot_name $BACKUP_DIR/failed-$snapshot_name
    mv $BACKUP_DIR/$HOST.log $BACKUP_DIR/failed-$HOST.log
    echo "Failed, logs are at $BACKUP_DIR/failed-$HOST.log"
    exit 1
  fi

  # Remove old dirs (>10 days)
  oldu=$(($nowu - 10*3600*24))
  for d in $(cd $BACKUP_DIR; ls -d snapshot.*); do
    timestr=$(echo $d | sed 's,snapshot.,,')
    timeu=$(date +%s -d"$(echo $timestr | tr '.' ':')")
    if [[ $timeu -gt 0 && $timeu -lt $oldu ]]; then
      echo "Removing $BACKUP_DIR/$d"
      rm -rf $BACKUP_DIR/$d
    fi
  done
done

echo "Done"
