#!/usr/bin/env bash
# This script is used to shrink the right side of polybar, and is largely used by
# the "collapse" module (an expand/compress icon).
#
# Every module has a "mini" twin (short label, e.g. "76%" instead of "76% [101 GB/451 GB]").
# Two independent switches:
#   size       mini (default) or full: which twin of each module is shown
#   collapsed  off (default) or on: hide every module that isn't ticked in the menu
#
#   flip <m> expand/shrink one module in place (left click on a module)
#   toggle   switch between mini and full (left click)
#   hide     turn "collapsed" on or off (middle click)
#   menu     rofi menu: switch size, switch collapsed, and tick what stays when collapsed (right click)
#   apply    re-send show/hide for every module (run after polybar starts)
#   chevron  print the label for polybar
#
# The choice is remembered in ~/.local/state/polybar/collapse.conf.
# MSG_CMD, ROFI_CMD and STATE can be overridden for testing.

msg="${MSG_CMD:-polybar-msg}"
rofi="${ROFI_CMD:-rofi}"
state="${STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/polybar/collapse.conf}"

all=(xautolock temperature volume cpu memory filesystem nordvpn tailscale internet date battery)
hasMini=" xautolock temperature volume cpu memory filesystem nordvpn tailscale internet date "
declare -A label=(
  [xautolock]="Screen lock" [temperature]="Temperature" [volume]="Volume" [cpu]="CPU"
  [memory]="Memory" [filesystem]="Disk" [nordvpn]="NordVPN" [tailscale]="Tailscale"
  [internet]="Network" [date]="Clock" [battery]="Battery"
)

size=mini
collapsed=off
keep="nordvpn date battery"
flipped="" # modules showing the opposite of "size" (clicked individually).
if [[ -r "$state" ]]; then
  while IFS='=' read -r k v; do
    case "$k" in size) size="$v" ;; collapsed) collapsed="$v" ;; keep | compact) keep="$v" ;; flipped) flipped="$v" ;; esac
  done <"$state"
fi

save() {
  mkdir -p "$(dirname "$state")"
  printf 'size=%s\ncollapsed=%s\nkeep=%s\nflipped=%s\n' "$size" "$collapsed" "$keep" "$flipped" >"$state"
}

kept() { [[ " $keep " == *" $1 "* ]]; }
shown() { [[ "$collapsed" == off ]] || kept "$1"; }

# effective prints the size a module is shown at: the global size, flipped if it was clicked.
effective() {
  if [[ " $flipped " == *" $1 "* ]]; then [[ "$size" == mini ]] && echo full || echo mini; else echo "$size"; fi
}

act() { "$msg" action "#$1.$2" >/dev/null 2>&1; }

apply() {
  local m rc=0
  for m in "${all[@]}"; do
    if [[ "$hasMini" != *" $m "* ]]; then # no mini twin: just show or hide it.
      if shown "$m"; then act "$m" module_show; else act "$m" module_hide; fi || rc=1
      continue
    fi
    if ! shown "$m"; then
      act "$m" module_hide; act "$m-mini" module_hide
    elif [[ "$(effective "$m")" == mini ]]; then
      act "$m" module_hide; act "$m-mini" module_show
    else
      act "$m-mini" module_hide; act "$m" module_show
    fi || rc=1
  done
  return $rc
}

# visible prints the modules polybar is drawing, left to right (the hover tooltips rely on this).
visible() {
  local m
  echo collapse
  for m in xautolock temperature volume cpu memory filesystem nordvpn tailscale internet date battery; do
    shown "$m" && echo "$m"
  done
  echo separator
}

chevron() {
  # ">" expands (shown while mini), "<" shrinks (shown while full).
  local icon='>' hidden=0 m
  [[ "$size" == full ]] && icon='<'
  if [[ "$collapsed" == on ]]; then
    for m in "${all[@]}"; do shown "$m" || hidden=$((hidden + 1)); done
    printf '%s %%{F#6272A4}-%s%%{F-}\n' "$icon" "$hidden"
  else
    printf '%s\n' "$icon"
  fi
}

toggle() { [[ "$size" == mini ]] && size=full || size=mini; flipped=""; save; apply; }

# flip expands (or shrinks again) one module in place, leaving the others alone.
flip() {
  local m="$1"
  [[ "$hasMini" == *" $m "* ]] || return 0
  if [[ " $flipped " == *" $m "* ]]; then flipped=$(tr ' ' '\n' <<<"$flipped" | grep -vx "$m" | xargs); else flipped=$(xargs <<<"$flipped $m"); fi
  save
  apply
}
hide() { [[ "$collapsed" == off ]] && collapsed=on || collapsed=off; save; apply; }

menu() {
  local entries m idx
  while true; do
    entries=("Size: ${size}   (choose to switch to $([[ "$size" == mini ]] && echo full || echo mini))"
      "Hide extras: ${collapsed}   (choose to switch; ticked modules always stay)")
    for m in "${all[@]}"; do
      if kept "$m"; then entries+=("[x] ${label[$m]}"); else entries+=("[ ] ${label[$m]}"); fi
    done
    idx=$(printf '%s\n' "${entries[@]}" | "$rofi" -dmenu -i -p "Bar" -no-custom -format i -l 14 -width 56) || return 0
    case "$idx" in
      0) toggle; continue ;;
      1) hide; continue ;;
    esac
    m="${all[idx - 2]}"
    if kept "$m"; then keep=$(tr ' ' '\n' <<<"$keep" | grep -vx "$m" | tr '\n' ' '); else keep="$keep $m"; fi
    keep=$(xargs <<<"$keep")
    save
    apply
  done
}

case "${1:-}" in
  toggle) toggle ;;
  flip) flip "${2:-}" ;;
  hide) hide ;;
  menu) menu ;;
  apply) apply ;;
  chevron) chevron ;;
  visible) visible ;;
  *) echo "usage: $0 flip <module>|toggle|hide|menu|apply|chevron" >&2; exit 2 ;;
esac
