#!/usr/bin/env bash
# This script is used to show where disk space is going, and is largely used as
# the click action for the filesystem module in polybar.
#
# Opens a rofi list with the usage of each mount and the biggest folders in your
# home directory. Pick a folder to explore it in ncdu (in a terminal). The folder
# sizes come from a cache so the popup opens instantly; "Rescan" refreshes it,
# and it also refreshes itself in the background when older than 15 minutes.
#
# ROFI_CMD, TERMINAL_CMD, NOTIFY_CMD, SCAN_ROOT, TOP and CACHE can be overridden
# for testing.

rofi="${ROFI_CMD:-rofi}"
terminal="${TERMINAL_CMD:-wezterm start --}"
notify="${NOTIFY_CMD:-notify-send}"
root="${SCAN_ROOT:-$HOME}"
top="${TOP:-15}"
cache="${CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/polybar-disk-details.txt}"
maxAge=900

# scan writes the biggest folders in $root to the cache (low priority, same filesystem only).
scan() {
  mkdir -p "$(dirname "$cache")"
  local tmp="$cache.$$"
  nice -n 19 ionice -c3 du -xh --max-depth=1 "$root" 2>/dev/null | sort -rh | head -n "$((top + 1))" >"$tmp" &&
    mv "$tmp" "$cache"
}

age() { echo $(($(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0))); }

if [[ ! -s "$cache" ]]; then
  "$notify" "Disk usage" "Scanning $root for the first time (can take up to a minute)..."
  scan
elif [[ "$(age)" -gt "$maxAge" ]]; then
  (scan &) >/dev/null 2>&1
fi

# Build the list: mounts first, then the rescan action, then the folders.
entries=$(
  df -h -x tmpfs -x devtmpfs -x efivarfs -x squashfs --output=pcent,used,size,avail,target 2>/dev/null |
    awk 'NR > 1 { printf "%-5s %s used of %s, %s free   %s\n", $1, $2, $3, $4, $5 }'
  echo "Rescan now  (cached $(($(age) / 60)) min ago)"
  # skip the first line, which is the total for $root itself.
  tail -n +2 "$cache" 2>/dev/null | awk '{ s = $1; $1 = ""; sub(/^ /, ""); printf "%-6s %s\n", s, $0 }'
)

choice=$(printf '%s\n' "$entries" | "$rofi" -dmenu -i -p "Disk" -no-custom -l 22 -width 60) || exit 0

case "$choice" in
"Rescan now"*)
  "$notify" "Disk usage" "Rescanning $root..."
  scan
  "$notify" "Disk usage" "Rescan finished."
  exec "$0"
  ;;
esac

# Folder lines look like "75G    /home/me/.local" - open that folder in ncdu.
dir=$(sed -E 's/^[^ ]+ +//' <<<"$choice")
if [[ -d "$dir" ]]; then
  # shellcheck disable=SC2086
  exec $terminal ncdu "$dir"
fi
