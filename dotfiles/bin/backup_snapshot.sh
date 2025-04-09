#!/bin/bash

set -x

BACKUP_SRC=${BACKUP_SRC-$HOME/qbm}

nowu=$(date +%s)
now=$(date -d@$nowu +%Y-%m-%dT%H:%M:%S)
HOSTS="localhost"

if [[ "$@" != "" ]]; then
  HOSTS="$@"
fi


for HOST in ${HOSTS}; do
  BACKUP_DIR=$HOME/.backup/$HOST

  mkdir -p $BACKUP_DIR

  snapshot_name=snapshot.$now
  if [[ $HOST == localhost ]]; then
    rsync -avPh --delete --link-dest=$BACKUP_DIR/current $BACKUP_SRC $BACKUP_DIR/$snapshot_name > $BACKUP_DIR/$HOST.$now.log 2>&1
  else 
    rsync -avPh --delete --link-dest=$BACKUP_DIR/current $HOST:$BACKUP_SRC $BACKUP_DIR/$snapshot_name > $BACKUP_DIR/$HOST.$now.log 2>&1
  fi

  if [[ $? == 0 ]]; then
    # Update symlink
    ln -nfs $BACKUP_DIR/$snapshot_name $BACKUP_DIR/current
  else
    # Rename dir if failed
    mv $BACKUP_DIR/$snapshot_name $BACKUP_DIR/failed-$snapshot_name
    mv $BACKUP_DIR/$HOST.$now.log $BACKUP_DIR/failed-$HOST.$now.log
    echo "Failed, logs are at $BACKUP_DIR/failed-$HOST.$now.log"
  fi

  # Remove old dirs (>60 days)
  oldu=$(($nowu - 60*3600*24))
  for d in $(cd $BACKUP_DIR; ls -d snapshot.*); do
    timestr=$(echo $d | sed 's,snapshot.,,')
    timeu=$(date -d"$timestr" +%s)
    if [[ $timeu -gt 0 && $timeu -lt $oldu ]]; then
      echo "Removing $BACKUP_DIR/$d"
      rm -rf $BACKUP_DIR/$d
    fi
  done
done
