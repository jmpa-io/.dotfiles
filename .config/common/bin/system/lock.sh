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
greeterPos=(--greeter-pos="x+947:y+450")
if hash magick scrot 2>/dev/null && scrot -o "$bg" 2>/dev/null &&
  read -r w h < <(magick identify -format '%w %h\n' "$bg"); then
  cx=$((w / 2)) cy=$((h / 2))
  greeterPos=(--greeter-pos="x+$cx:y+$((cy + 125))" --greeter-align=2)
  boxW=420 boxH=104 boxTop=$((cy + 200 + 40))
  details="$(printf '%s@%s\nlocked at %s\nup %s' "${USER:-$(id -un)}" "${HOSTNAME%%.*}" \
    "$(date '+%H:%M')" "$(uptime -p 2>/dev/null | sed 's/^up //')")"
  magick "$bg" -blur 0x10 \
    -fill '#282a36d9' -stroke '#bd93f9' -strokewidth 2 \
    -draw "roundrectangle $((cx - boxW / 2)),$boxTop $((cx + boxW / 2)),$((boxTop + boxH)) 14,14" \
    -stroke none -fill '#f8f8f2' -font FiraCode-Nerd-Font-Reg -pointsize 18 -gravity northwest \
    -interline-spacing 6 -annotate "+$((cx - boxW / 2 + 28))+$((boxTop + 16))" "$details" "$bg" 2>/dev/null &&
    bgArgs=(--image="$bg")
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
  --verif-font="FiraCode Nerd Font" \
  --wrong-font="FiraCode Nerd Font" \
  --greeter-font="FiraCode Nerd Font" \
  --greeter-size=100 \
  "${greeterPos[@]}" \
  --time-size=72 \
  --date-size=24 \
  --verif-size=24 \
  --wrong-size=24 \
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
  --greeter-color="$green" \
  --modif-color="$red" \
  --layout-color="$blue" \
  --date-color="$cyan" \
  --time-color="$magenta"
