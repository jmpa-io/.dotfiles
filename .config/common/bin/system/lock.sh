#!/usr/bin/env bash
# uses i3lock to lock the screen on this machine.

# check deps.
hash i3lock || { echo "missing i3lock"; exit 1; }

# colors.
yellow="#f1fa8c"
orange="#ffb86c"
red="#ff5555"
magenta="#ff79c6"
blue="#6272a4"
cyan="#8be9fd"
green="#50fa7b"
grey="#44475a"

# lock screen.
i3lock \
  \
  --time-str="%H:%M %p" \
  --date-str="%A, %e %B %Y" \
  --screen 1 \
  --blur 10 \
  --clock \
  --indicator \
  --ignore-empty-password \
  --pointer=default \
  --line-uses-ring \
  --pass-media-keys \
  --pass-screen-keys \
  --pass-volume-keys \
  --pass-power-keys \
  --radius=200 \
  --ring-width=20 \
  --greeter-font="FiraCode Nerd Font" \
  --greeter-size=100 \
  --greeter-pos="x+947:y+450" \
  --verif-size=24 \
  --wrong-size=24 \
  \
  --greeter-text="" \
  --verif-text="Checking..." \
  --wrong-text="Try again!" \
  --noinput="Please type your password." \
  --lock-text="Locking..." \
  --lockfailed-text="Locking failed!" \
  \
  --insidever-color="$grey" \
  --insidewrong-color="$grey" \
  --inside-color="$grey" \
  --ringver-color="$green" \
  --ringwrong-color="$red" \
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

