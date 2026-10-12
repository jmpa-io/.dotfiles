#!/usr/bin/env bash
# This script takes screenshots with scrot (full screen, active window, or a
# selection), saved to a directory or copied to the clipboard. It replaces
# Manjaro's 'i3-scrot', so the same i3 config works on Manjaro and Arch Linux.
#
# The destination can be set in ~/.config/i3-scrot.conf (scrot_dir=...), or with
# I3_SCROT_DIR. The default is your XDG pictures directory.

for dep in scrot notify-send; do
  hash "$dep" 2>/dev/null || { echo "missing $dep" >&2; exit 1; }
done

conf="$HOME/.config/i3-scrot.conf"
# shellcheck source=/dev/null
[[ -f "$conf" ]] && source "$conf"
scrot_dir="${I3_SCROT_DIR:-${scrot_dir:-$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")}}"
mkdir -p "$scrot_dir" || exit 1
cd "$scrot_dir" || exit 1

usage() {
  cat <<EOF
available options:
-d  | --desk                  full screen (default)
-w  | --window                active window
-s  | --select                selection
-dc | --desk-to-clipboard     full screen to clipboard
-wc | --window-to-clipboard   active window to clipboard
-sc | --select-to-clipboard   selection to clipboard
-h  | --help                  display this information

The -d, -w, -dc and -wc options take a delay in seconds, like: 'i3-scrot.sh -w 5'.
Destination: $scrot_dir (set in $conf).
EOF
}

# scrot's clipboard handling needs xclip ($f is expanded by scrot, not by us).
# shellcheck disable=SC2016
clip=(-e 'xclip -selection clipboard -t image/png -i $f && rm $f')
delay=()
[[ -n "$2" ]] && delay=(-d "$2")

saved()  { sleep 1; notify-send "screenshot has been saved in $scrot_dir"; }
copied() { sleep 1; notify-send "screenshot has been copied to clipboard"; }

case "$1" in
  ""|-d|--desk)                   scrot "${delay[@]}" && saved ;;
  -w|--window)                    scrot "${delay[@]}" -u && saved ;;
  -s|--select)                    notify-send 'select an area for the screenshot' &
                                  scrot -s && saved ;;
  -dc|--desk-to-clipboard)        scrot "${delay[@]}" "${clip[@]}" && copied ;;
  -wc|--window-to-clipboard)      scrot "${delay[@]}" -u "${clip[@]}" && copied ;;
  -sc|--select-to-clipboard)      notify-send 'select an area for the screenshot' &
                                  scrot -s "${clip[@]}" && copied ;;
  -h|--help)                      usage ;;
  *)                              echo "i3-scrot: missing or wrong argument" >&2; usage >&2; exit 2 ;;
esac
