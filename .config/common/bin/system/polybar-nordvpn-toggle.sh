#!/usr/bin/env bash
# This script is used to connect or disconnect NordVPN with a click in polybar.
# Connects to the fastest server when disconnected, and disconnects when connected.
# Sends a desktop notification with the result.
#
# NORDVPN_CMD and NOTIFY_CMD can be overridden for testing.

nordvpn="${NORDVPN_CMD:-nordvpn}"
notify="${NOTIFY_CMD:-notify-send}"

status=$(timeout 3 "$nordvpn" status 2>&1 | sed -nE 's/^[[:space:]]*Status:[[:space:]]*(.*)$/\1/p' | head -1)

if [[ -z "$status" ]]; then
  "$notify" "NordVPN" "Daemon not running or not logged in (run: nordvpn login)"
  exit 1
fi

if [[ "$status" == "Connected" ]]; then
  out=$("$nordvpn" disconnect 2>&1)
else
  out=$("$nordvpn" connect 2>&1)
fi
"$notify" "NordVPN" "$(tr -d '\r' <<<"$out" | tail -1)"
