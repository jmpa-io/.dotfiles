#!/usr/bin/env bash

# terminate any existing instances of polybar.
killall -q polybar

# launch bar.
echo "---" | tee -a /tmp/polybar.log
polybar top -c "$HOME/.config/polybar/config.ini" 2>&1 | tee -a /tmp/polybar.log & disown

echo "Bars launched..."
