#!/usr/bin/env bash
# uses i3lock to lock the screen on this machine.

# check deps.
hash i3lock || {
  echo "missing i3lock"
  exit 1
}

# colors (Dracula, toned down). i3lock wants RRGGBBAA without the '#'.
fg="f8f8f2ff"
muted="a9b1d6ff"
ring="6272a4ff"
panel="1e1f29d9"
accent="8be9fd"
orange="ffb86c"
red="ff5555"

# lock screen.
i3lock \
  \
  --time-str="%I:%M %p" \
  --date-str="%A, %e %B" \
  --screen 1 \
  --blur 12 \
  --clock \
  --indicator \
  --ignore-empty-password \
  --show-failed-attempts \
  --pointer=default \
  --pass-media-keys \
  --pass-screen-keys \
  --pass-volume-keys \
  --pass-power-keys \
  --radius=170 \
  --ring-width=4 \
  --time-size=56 \
  --date-size=18 \
  --verif-size=16 \
  --wrong-size=16 \
  --greeter-text="" \
  --verif-text="Verifying..." \
  --wrong-text="Incorrect. 6 fails = 30s lockout" \
  --noinput="Enter your password" \
  --lock-text="Locking..." \
  --lockfailed-text="Locking failed" \
  \
  --inside-color="$panel" \
  --insidever-color="$panel" \
  --insidewrong-color="$panel" \
  --ring-color="$ring" \
  --ringver-color="${accent}ff" \
  --ringwrong-color="${red}ff" \
  --line-color="00000000" \
  --separator-color="00000000" \
  --keyhl-color="${fg}" \
  --bshl-color="${orange}ff" \
  --time-color="$fg" \
  --date-color="$muted" \
  --verif-color="${accent}ff" \
  --wrong-color="${red}ff" \
  --modif-color="${red}ff" \
  --layout-color="$muted"
