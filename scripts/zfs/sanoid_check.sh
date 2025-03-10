#!/usr/bin/env bash

# this scripts checks if sanoid is working correctly, by:
# - checking last systemd run
# - checking snapshot date

# failure must lead to failure !
set -e 

SNAP_MIN_DATE="7 hours ago"
SANOID_MIN_DATE="7 hours ago"
ERRORS=()

function get_zfs_volumes {
 # get all sections but templates and remove brackets
 ZFS_VOLUMES=( \
   $( \
     cat /etc/sanoid/sanoid.conf | \
     grep  '^\[.\+\]' | grep -v '\[template_' | \
     sed -e 's/\[\(.\+\)\]/\1/' \
   ) \
 );
}

function check_last_snap_date {
  # check for a volume last snapshot date
  local VOL_PATH=$1
  # list snapshots
  local last_snap=$(zfs list "$VOL_PATH" -t snap|grep 'autosnap_.*_hourly'|sort |tail -n 1)
  # get date from name
  local last_date=$(echo $last_snap | sed -e 's/^.*autosnap_\([0-9-]\+\)_\([0-9:]\+\)_hourly.*$/\1 \2/g')
  # compare timestamps
  local last_ts=$(date --date="$last_date" "+%s")
  local min_ts=$(date -d "$SNAP_MIN_DATE" "+%s")
  if [[ "$last_ts" -lt "$min_ts" ]]
  then
    ERRORS+=("Last snapshot for $VOL_PATH is too old: $last_date")
  fi
}

function check_sanoid_run_date {
  # check last sanoid service run time
  local last_run_date=$(systemctl show sanoid.service --property=ExecMainExitTimestamp|cut -d "=" -f 2)
  local last_run_ts=$(echo "$last_run_date"|date "+%s")
  local min_ts=$(date -d "$SANOID_MIN_DATE" "+%s")
  if [[ "$last_run_ts" -lt "$min_ts" ]]
  then
    ERRORS+="Sanoid did not run for too long a time: $last_run_date"
  fi
}

# first check sanoid
check_sanoid_run_date
# then each volume
get_zfs_volumes
for volume in "${ZFS_VOLUMES[@]}"
do
  check_last_snap_date "$volume"
done

# if errors send email
if [[ "${#ERRORS[@]}" -ne "0" ]]
then
  printf '%s\n' "${ERRORS[@]}" | mailx -s "$0 error on $HOSTNAME" root
fi



