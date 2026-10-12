#!/usr/bin/env bash
# This script is the volume module for polybar: one module that shows the volume, mutes, and
# changes the volume. It replaces the separate alsa/mute modules.
#
#   status [--mini]  print the module for polybar, again whenever the volume or mute state changes
#                    (mini: icon and percentage; full: icon, slider and percentage)
#   once [--mini]    print the line once and exit
#   up | down        change the volume by 5% (never above 100%)
#   mute             toggle mute for the speakers
#   mic              toggle mute for the microphone
#   outputs          pick the sound output (rofi)
#
# In the bar: click the speaker icon to mute, click the percentage or slider to expand/shrink,
# scroll anywhere on it to change the volume. PACTL, STEP, ROFI_CMD and COLLAPSE can be overridden
# for testing.

pactl="${PACTL:-pactl}"
step="${STEP:-5}"
rofi="${ROFI_CMD:-rofi}"
collapse="${COLLAPSE:-$HOME/bin/system/polybar-collapse.sh}"
self="$(readlink -f "$0")"
sink='@DEFAULT_SINK@'
source='@DEFAULT_SOURCE@'

volume() { "$pactl" get-sink-volume "$sink" 2>/dev/null | grep -o '[0-9]*%' | head -1 | tr -d '%'; }
muted() { [[ "$("$pactl" get-sink-mute "$sink" 2>/dev/null)" == *yes* ]]; }

# render prints one line. %{T3} is "Font Awesome 6 Free Solid".
render() {
  local mini="$1" vol icon bar="" filled i width=10
  vol=$(volume)
  [[ -z "$vol" ]] && {
    echo "%{F#6272A4}%{T3}$(printf '')%{T-} n/a%{F-}"
    return
  }
  local a="%{A1:$self mute:}%{A4:$self up:}%{A5:$self down:}"
  local b="%{A1:$collapse flip volume:}%{A4:$self up:}%{A5:$self down:}"
  if muted; then
    icon="%{F#FF5555}%{T3}$(printf '')%{T-}%{F-}"
    echo "${a} ${icon} %{A}%{A}%{A}${b} %{F#FF5555}muted%{F-} %{A}%{A}%{A}"
    return
  fi
  if ((vol == 0)); then icon=$(printf ''); elif ((vol < 50)); then icon=$(printf ''); else icon=$(printf ''); fi
  icon="%{T3}${icon}%{T-}"
  if [[ "$mini" == 1 ]]; then
    echo "${a} ${icon} %{A}%{A}%{A}${b} ${vol}% %{A}%{A}%{A}"
    return
  fi
  filled=$((vol * width / 100))
  ((filled > width - 1)) && filled=$((width - 1))
  for ((i = 0; i < width; i++)); do
    if ((i < filled)); then bar+="─"; elif ((i == filled)); then bar+="%{F#F8F8F2}|%{F-}%{F#6272A4}"; else bar+="─"; fi
  done
  echo "${a} ${icon} %{A}%{A}%{A}${b} ${bar}%{F-} ${vol}% %{A}%{A}%{A}"
}

change() {
  local v target
  v=$(volume)
  [[ -z "$v" ]] && exit 0
  if [[ "$1" == up ]]; then target=$((v + step)); else target=$((v - step)); fi
  ((target > 100)) && target=100
  ((target < 0)) && target=0
  "$pactl" set-sink-volume "$sink" "${target}%"
}

case "${1:-}" in
status)
  mini=0
  [[ "${2:-}" == --mini ]] && mini=1
  render "$mini"
  # redraw on every sink change (volume, mute, default output) as it happens.
  "$pactl" subscribe 2>/dev/null | grep --line-buffered -E "on (sink|server) " | while read -r _; do render "$mini"; done
  ;;
once) render "$([[ "${2:-}" == --mini ]] && echo 1 || echo 0)" ;; # one line, for testing.
up | down) change "$1" ;;
mute) "$pactl" set-sink-mute "$sink" toggle ;;
mic) "$pactl" set-source-mute "$source" toggle ;;
outputs)
  choice=$("$pactl" list short sinks | awk '{ print $2 }' | "$rofi" -dmenu -i -p "Output" -no-custom) || exit 0
  [[ -n "$choice" ]] && "$pactl" set-default-sink "$choice"
  ;;
*)
  echo "usage: $0 status [--mini]|up|down|mute|mic|outputs" >&2
  exit 2
  ;;
esac
