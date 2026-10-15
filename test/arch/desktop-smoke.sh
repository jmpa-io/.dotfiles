#!/usr/bin/env bash
# Headless desktop smoke test. Starts Xvfb + i3 + polybar + dunst on a virtual
# display, sends test notifications, and (if /out is mounted) saves a screenshot
# to /out/desktop.png so you can see what a clean install renders.
# Needs the desktop packages installed first (make install-desktop).
# Each check prints PASS/FAIL; the exit code is the number of failed checks.
# shellcheck disable=SC2016  # inner 'bash -c' shells must expand variables, not this one.

fails=0
check() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "PASS: $name"; else echo "FAIL: $name"; fails=$((fails + 1)); fi
}

export DISPLAY=:99
Xvfb :99 -screen 0 1920x1080x24 >/tmp/xvfb.log 2>&1 &
sleep 2
check "virtual display is up" xdpyinfo -display :99

# a session bus, so dunst can claim the notification name.
eval "$(dbus-launch --sh-syntax)"

i3 -c "$HOME/.i3/config" >/tmp/i3.log 2>&1 &
sleep 3
check "i3 is running" i3-msg -t get_version

# i3's own autostart (exec_always) launches polybar via launch.sh.
sleep 4
check "polybar is running" pgrep -x polybar

dunst -config "$HOME/.config/dunst/dunstrc" >/tmp/dunst.log 2>&1 &
sleep 2
check "dunst is running" pgrep -x dunst

notify-send "Smoke test" "Normal notification"
notify-send -u critical "Smoke test" "Critical notification"
sleep 1
check "dunst received the notifications" bash -c '[[ "$(dunstctl count displayed)" -ge 2 ]]'

# the portable replacements for the Manjaro scripts.
check "i3exit dry-run" env I3EXIT_DRY_RUN=1 "$HOME/bin/system/i3exit.sh" logout
check "i3-scrot takes a screenshot" env I3_SCROT_DIR=/tmp/shots "$HOME/bin/system/i3-scrot.sh" -d
check "screenshot file was written" bash -c 'ls /tmp/shots/*.png'

if [[ -d /out ]]; then
  sleep 1
  import -window root /out/desktop.png && echo "screenshot saved to /out/desktop.png"
fi

echo; echo "--- errors worth reading:"
grep -iE 'error|failed|not found' /tmp/i3.log /tmp/dunst.log 2>/dev/null | head -10
echo "--- polybar:"; (pgrep -ax polybar | head -1)
echo "=== DESKTOP SMOKE: $fails check(s) failed"
exit "$fails"
