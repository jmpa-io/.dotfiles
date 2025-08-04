#!/usr/bin/env bash

# Terminate any existing instances of polybar.
killall -q polybar

# Wait until the processes have been shut down.
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.5; done

# launch a bar per monitor.
echo "---" | tee -a /tmp/polybar.log
for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
  MONITOR="$m" polybar top -c "$HOME/.config/polybar/config.ini" 2>&1 | tee -a /tmp/polybar.log & disown
done

echo "Bars launched..."
