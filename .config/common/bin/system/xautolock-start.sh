#!/usr/bin/env bash
# This script sets up autolocking to lock this machine after 'x' amount of time.
#
# PLEASE NOTE: This script is intended to run:
# - at system boot (by i3).
# - when toggled (by polybar).

# Exit early if xautolock is already running.
pidFile="$HOME/.xautolock.pid"
if [[ -f "$pidFile" ]]; then
  ps -p $(<"$pidFile") >/dev/null 2>&1 \
    && { exit 0; }
fi

# Start xautolock.
xautolock -time 10 -locker "$HOME/bin/system/lock.sh" &
pid="$!"
disown "$pid"
ps -p "$pid" >/dev/null 2>&1 \
  && { echo "$pid" > "$pidFile"; }
