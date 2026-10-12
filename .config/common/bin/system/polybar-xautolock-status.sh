#!/usr/bin/env bash
# This script is used to determine if xautolock is currently locked or not,
# and is largely used to display an icon in polybar.

# Check if xautolock is running.
pidFile="$HOME/.xautolock.pid"
if [[ -f "$pidFile" ]]; then
  if ps -p "$(<"$pidFile")" >/dev/null 2>&1; then
    [[ "${1:-}" == "--mini" ]] && echo "%{F#7EE081}🔒%{F-}" || echo "🖥️ [%{F#7EE081}🔒%{F-}]"
    exit 0
  fi
fi

[[ "${1:-}" == "--mini" ]] && echo "%{F#E07E7E}🔓%{F-}" || echo "🖥️ [%{F#E07E7E}🔓%{F-}]"

