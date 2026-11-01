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
  details="$(printf '%s@%s\nlocked at %s\nup %s' "${USER:-$(id -un)}" "${HOSTNAME%%.*}" \
    "$(date '+%H:%M')" "$(uptime -p 2>/dev/null | sed 's/^up //')")"
  # size the box to its text so the padding is even.
  read -r tw th < <(magick -font FiraCode-Nerd-Font-Reg -pointsize 18 -interline-spacing 6 \
    label:"$details" -format '%w %h\n' info:)
  pad=20 boxW=$((tw + pad * 2)) boxH=$((th + pad * 2)) boxTop=$((cy + 219 + 22))
  magick "$bg" -blur 0x10 -fill '#282a3659' -draw "rectangle 0,0 $w,$h" \
    -fill '#282a36d9' -stroke '#bd93f9' -strokewidth 2 \
    -draw "roundrectangle $((cx - boxW / 2)),$boxTop $((cx + boxW / 2)),$((boxTop + boxH)) 14,14" \
    -stroke none -font FiraCode-Nerd-Font-Reg -gravity northwest -pointsize 18 -fill '#f8f8f2' \
    -interline-spacing 6 -annotate "+$((cx - tw / 2))+$((boxTop + pad))" "$details" "$bg" 2>/dev/null &&
    bgArgs=(--image="$bg") &&
    greeterArgs=(--greeter-pos="ix-42:iy+120" --greeter-align=1 --greeter-color="$green")
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
  --time-pos="ix:iy-10" \
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
