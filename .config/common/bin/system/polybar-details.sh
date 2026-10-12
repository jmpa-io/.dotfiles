#!/usr/bin/env bash
# This script shows more information about a polybar module, and is used as the
# click action for the modules in polybar.
#
# Usage: polybar-details.sh <module> [tip]
#   <module>      popup (rofi) with details and, where it makes sense, actions
#   <module> tip  short tooltip-style notification instead
#   <module> text print the short tooltip text (used by the hover tooltips, polybar-hover.py)
#
# Lines starting with ">" are actions; picking one runs it. Everything else is info.
# ROFI_CMD, NOTIFY_CMD and BIN can be overridden for testing.

rofi="${ROFI_CMD:-rofi}"
notify="${NOTIFY_CMD:-notify-send}"
bin="${BIN:-$HOME/bin/system}"

module="${1:-}"
mode="${2:-popup}"

# info prints the lines for a module. Actions are declared by calling action().
info() {
  case "$module" in
    cpu)
      echo "$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ //')"
      echo "Load average: $(cut -d' ' -f1-3 /proc/loadavg)   Cores: $(nproc)"
      echo "Busiest processes:"
      ps -eo pcpu,comm --sort=-pcpu | awk 'NR > 1 && NR <= 6 { printf "  %5s%%  %s\n", $1, $2 }'
      action "Open system monitor" "wezterm start -- htop"
      ;;
    memory)
      free -h | awk 'NR == 2 { printf "Used %s of %s (%s available)\n", $3, $2, $7 } NR == 3 { printf "Swap %s of %s\n", $3, $2 }'
      echo "Biggest processes:"
      ps -eo pmem,rss,comm --sort=-rss | awk 'NR > 1 && NR <= 6 { printf "  %5s%%  %5d MB  %s\n", $1, $2 / 1024, $3 }'
      action "Open system monitor" "wezterm start -- htop"
      ;;
    temperature)
      local z
      for z in /sys/class/thermal/thermal_zone*; do
        [[ -r $z/temp ]] && printf '%-14s %s°C\n' "$(<"$z/type")" "$(($(<"$z/temp") / 1000))"
      done
      ;;
    volume)
      local sink
      sink=$(pactl get-default-sink 2>/dev/null)
      echo "Output: ${sink:-unknown}"
      echo "Speakers: $(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]*%' | head -1), muted: $(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{ print $2 }')"
      echo "Microphone: $(pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null | grep -o '[0-9]*%' | head -1), muted: $(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | awk '{ print $2 }')"
      echo "Speaker icon: mute.  Number or slider: expand.  Scroll: volume."
      action "Mute / unmute speakers" "$bin/polybar-volume.sh mute"
      action "Mute / unmute microphone" "$bin/polybar-volume.sh mic"
      action "Switch sound output" "$bin/polybar-volume.sh outputs"
      action "Open mixer (pavucontrol)" "pavucontrol"
      ;;
    internet)
      nmcli -t -f active,ssid,signal,rate dev wifi list --rescan no 2>/dev/null | awk -F: '$1 == "yes" { printf "Network: %s\nSignal: %s%%   Rate: %s\n", $2, $3, $4 }'
      echo "Address: $(ip -4 -o addr show wlp2s0 2>/dev/null | awk '{ print $4 }')"
      echo "Gateway: $(ip route show default 2>/dev/null | awk '{ print $3; exit }')"
      action "Edit connections" "nm-connection-editor"
      ;;
    date)
      LC_TIME=C date '+%A, %d %B %Y   week %V'
      echo
      cal -m 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g'
      ;;
    battery)
      local b=/sys/class/power_supply/BAT0
      echo "Charge: $(<$b/capacity)% ($(<$b/status))"
      [[ -r $b/energy_now && -r $b/power_now ]] && echo "Power draw: $(awk -v p="$(<$b/power_now)" 'BEGIN { printf "%.1f W", p / 1e6 }')"
      [[ -r $b/energy_full && -r $b/energy_full_design ]] && echo "Health: $(($(<$b/energy_full) * 100 / $(<$b/energy_full_design)))% of design capacity"
      ;;
    nordvpn)
      local st
      st=$(nordvpn status 2>&1 | sed 's/\r//; /^[[:space:]]*$/d' | grep -v '^[-\\|/]')
      echo "$st"
      if grep -q 'Status: Connected' <<<"$st"; then
        action "Disconnect" "$bin/polybar-nordvpn-toggle.sh"
      else
        action "Connect" "$bin/polybar-nordvpn-toggle.sh"
      fi
      ;;
    tailscale)
      tailscale status 2>&1 | head -12
      action "Turn on / off" "$bin/polybar-tailscale-toggle.sh"
      ;;
    xautolock)
      if pgrep -x xautolock >/dev/null; then echo "Auto-lock is ON"; else echo "Auto-lock is OFF"; fi
      action "Turn auto-lock on / off" "$bin/polybar-xautolock-toggle.sh"
      action "Lock screen now" "loginctl lock-session"
      ;;
    collapse)
      echo "Click: switch the whole bar between mini and full"
      echo "Middle-click: hide the modules you didn't tick"
      echo "Right-click: bar menu"
      ;;
    filesystem)
      if [[ "$mode" == tip ]]; then
        df -h -x tmpfs -x devtmpfs -x efivarfs -x squashfs --output=pcent,used,size,target | tail -n +2
      else
        exec "$bin/polybar-disk-details.sh"
      fi
      ;;
    *) echo "unknown module: $module" ;;
  esac
}

declare -A actions
order=()
action() { actions["> $1"]="$2"; order+=("> $1"); }

# Run info in this shell (not a subshell) so action() registers the actions.
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
info >"$tmp"
lines=$(<"$tmp")

if [[ "$mode" == text ]]; then
  grep -v '^>' <<<"$lines" | head -8
  exit 0
fi

if [[ "$mode" == tip ]]; then
  # keep tooltips short: the first few non-action lines, replacing the previous tooltip.
  body=$(grep -v '^>' <<<"$lines" | head -5)
  "$notify" -t 5000 -u low -h string:x-dunst-stack-tag:polybar-tip "${module^}" "$body"
  exit 0
fi

menu="$lines"
for a in "${order[@]}"; do menu+=$'\n'"$a"; done
menu=$(grep -v '^[[:space:]]*$' <<<"$menu")

choice=$(printf '%s\n' "$menu" | "$rofi" -dmenu -i -p "${module^}" -no-custom -l "$(wc -l <<<"$menu")" \
  -theme-str 'window { width: 520px; anchor: northeast; location: northeast; y-offset: 36; x-offset: -8; }') || exit 0

if [[ -n "${actions[$choice]:-}" ]]; then
  eval "${actions[$choice]}" >/dev/null 2>&1 &
fi
