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

# apply the remembered view (mini by default). Modules start out all visible, so apply as soon
# as polybar's ipc answers, and once more after the modules have started.
collapse="$HOME/bin/system/polybar-collapse.sh"
for _ in $(seq 1 30); do "$collapse" apply && break; sleep 0.1; done
sleep 1
"$collapse" apply

# hover tooltips: watch the mouse and show a tooltip for the module it rests on.
pidFile="${XDG_RUNTIME_DIR:-/tmp}/polybar-hover.pid"
[[ -f "$pidFile" ]] && kill "$(<"$pidFile")" 2>/dev/null
"$HOME/bin/system/polybar-hover.py" >/dev/null 2>&1 &
echo $! >"$pidFile"
