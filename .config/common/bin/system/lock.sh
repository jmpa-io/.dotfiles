#!/usr/bin/env bash
# uses i3lock to lock the screen on this machine.

# check deps.
hash i3lock || {
  echo "missing i3lock"
  exit 1
}

# colors.
# shellcheck disable=SC2034  # some colors unused directly but kept for reference/future use
yellow="#f1fa8c"
orange="#ffb86c"
red="#ff5555"
magenta="#ff79c6"
blue="#6272a4"
cyan="#8be9fd"
green="#50fa7b"
grey="#44475a"

# background: the blurred screen with a boxed info panel under the ring. Falls
# back to i3lock's own blur if scrot/imagemagick are missing or fail: the screen
# must lock either way.
bg="$(mktemp --suffix=.png)"
trap 'rm -f "$bg"' EXIT

bgArgs=(--blur 10)
greeterArgs=(--greeter-pos="x+947:y+450" --greeter-color="$green")
if hash magick scrot 2>/dev/null && scrot -o "$bg" 2>/dev/null &&
  read -r w h < <(magick identify -format '%w %h\n' "$bg"); then
  cx=$((w / 2)) cy=$((h / 2))
  user="${USER:-$(id -un)}"
  up="$(uptime -p 2>/dev/null | sed 's/^up //')"
  font=FiraCode-Nerd-Font-Reg fs=17 rowH=26 titleH=26 pad=18
  # monospace: measure one char, then size the box from the longest value.
  read -r charW16 _ < <(magick -font "$font" -pointsize "$fs" label:'################' -format '%w %h\n' info:)
  charW=$((charW16 / 16 + 1))
  keyW=$((charW * 8))
  longest=$(printf '%s\n' "$user@${HOSTNAME%%.*}" "$(date '+%H:%M')" "$up" | awk '{ if (length($0) > m) m = length($0) } END { print m }')
  boxW=$((pad * 2 + keyW + charW * longest)) boxH=$((titleH + 12 + rowH * 3 + 4))
  boxX=$((cx - boxW / 2)) boxTop=$((cy + 219 + 20)) tx=$((cx - boxW / 2 + pad))
  rowsTop=$((boxTop + titleH + 12))
  # no -gravity: -annotate then positions by baseline, so mixed glyph heights line up.
  row() { # key value index
    printf -- '-fill\n#8be9fd\n-annotate\n+%d+%d\n%s\n-fill\n#f8f8f2\n-annotate\n+%d+%d\n%s\n' \
      "$tx" "$((rowsTop + ($3 + 1) * rowH - 8))" "$1" "$((tx + keyW))" "$((rowsTop + ($3 + 1) * rowH - 8))" "$2"
  }
  mapfile -t rows < <(
    row user "$user@${HOSTNAME%%.*}" 0
    row locked "$(date '+%H:%M')" 1
    row uptime "$up" 2
  )
  magick "$bg" -blur 0x10 -fill '#282a3659' -draw "rectangle 0,0 $w,$h" \
    -fill '#282a36e6' -stroke '#bd93f9' -strokewidth 2 \
    -draw "roundrectangle $boxX,$boxTop $((boxX + boxW)),$((boxTop + boxH)) 12,12" \
    -stroke none -fill '#44475a' -draw "rectangle $((boxX + 2)),$((boxTop + titleH)) $((boxX + boxW - 2)),$((boxTop + titleH + 1))" \
    -fill '#ff5555' -draw "circle $((boxX + 18)),$((boxTop + 13)) $((boxX + 18 + 5)),$((boxTop + 13))" \
    -fill '#f1fa8c' -draw "circle $((boxX + 36)),$((boxTop + 13)) $((boxX + 36 + 5)),$((boxTop + 13))" \
    -fill '#50fa7b' -draw "circle $((boxX + 54)),$((boxTop + 13)) $((boxX + 54 + 5)),$((boxTop + 13))" \
    -font "$font" -pointsize "$fs" "${rows[@]}" "$bg" 2>/dev/null &&
    bgArgs=(--image="$bg") &&
    greeterArgs=(--greeter-pos="ix-42:iy-40" --greeter-align=1 --greeter-color="$green")
fi

# lock screen.
i3lock \
  "${bgArgs[@]}" \
  --time-str="%I:%M %p" \
  --date-str="%A, %-d %B %Y" \
  --screen 1 \
  --clock \
  --indicator \
  --ignore-empty-password \
  --show-failed-attempts \
  --pointer=default \
  --line-uses-ring \
  --pass-media-keys \
  --pass-screen-keys \
  --pass-volume-keys \
  --pass-power-keys \
  --radius=200 \
  --ring-width=20 \
  --time-font="FiraCode Nerd Font Propo SemBd" \
  --date-font="FiraCode Nerd Font" \
  --layout-font="FiraCode Nerd Font" \
  --time-pos="ix:iy+40" \
  --date-pos="tx:ty+36" \
  --verif-font="FiraCode Nerd Font" \
  --wrong-font="FiraCode Nerd Font" \
  --greeter-font="FiraCode Nerd Font" \
  --greeter-size=100 \
  "${greeterArgs[@]}" \
  --time-size=60 \
  --date-size=24 \
  --verif-size=24 \
  --wrong-size=19 \
  \
  --greeter-text="" \
  --verif-text="Checking..." \
  --wrong-text="Wrong. 6 fails = 30s lockout" \
  --noinput="Please type your password." \
  --lock-text="Locking..." \
  --lockfailed-text="Locking failed!" \
  \
  --insidever-color="$grey" \
  --insidewrong-color="$grey" \
  --inside-color="$grey" \
  --ringver-color="$green" \
  --ringwrong-color="$red" \
  --ring-color="$blue" \
  --keyhl-color="$magenta" \
  --bshl-color="$orange" \
  --separator-color="$grey" \
  --verif-color="$green" \
  --wrong-color="$red" \
  --modif-color="$red" \
  --layout-color="$blue" \
  --date-color="$cyan" \
  --time-color="$magenta"
