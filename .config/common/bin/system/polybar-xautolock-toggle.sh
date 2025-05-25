#!/usr/bin/env bash
# This script turns on, or off, xautolock.

# Check if xautolock is running; Turn it off if it is.
pidFile="$HOME/.xautolock.pid"
if [[ -f "$pidFile" ]]; then
  pid=$(<"$pidFile")
  if ps -p "$pid" >/dev/null 2>&1; then
    kill "$pid" && rm -f "$pidFile"
    exit 0
  fi
fi

# Start xautolock.
"$HOME/bin/system/xautolock-start.sh"

