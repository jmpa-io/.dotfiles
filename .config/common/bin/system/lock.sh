#!/usr/bin/env bash
# uses i3lock to lock the screen on this machine.

hash i3lock 2>/dev/null || {
  echo "missing i3lock"
  exit 1
}

# colors (Dracula, toned down).
fg="f8f8f2ff"; muted="a9b1d6ff"; accent="8be9fd"; orange="ffb86c"; red="ff5555"

# background: blurred screenshot with a squircle panel (|x|^n + |y|^n = 1) in
# the middle. Falls back to plain i3lock blur if scrot/imagemagick/awk are missing
# or fail: the screen must lock either way.
bg="$(mktemp --suffix=.png)"
trap 'rm -f "$bg"' EXIT
bgArgs=(--blur 12)
if hash scrot magick awk 2>/dev/null && scrot -o "$bg" 2>/dev/null &&
  read -r w h < <(magick identify -format '%w %h\n' "$bg"); then
  points=$(awk -v cx=$((w / 2)) -v cy=$((h / 2)) -v r=200 -v n=5 'BEGIN {
    for (i = 0; i < 160; i++) {
      t = 2 * 3.14159265 * i / 160; c = cos(t); s = sin(t)
      x = (c < 0 ? -1 : 1) * (c < 0 ? -c : c) ^ (2 / n)
      y = (s < 0 ? -1 : 1) * (s < 0 ? -s : s) ^ (2 / n)
      printf "%.1f,%.1f ", cx + r * x, cy + r * y
    }
  }')
  magick "$bg" -blur 0x12 -fill '#1e1f29d9' -stroke '#6272a4' -strokewidth 2 \
    -draw "polygon $points" "$bg" && bgArgs=(--image="$bg")
fi

i3lock \
  "${bgArgs[@]}" \
  --time-str="%I:%M %p" \
  --date-str="%A, %e %B" \
  --screen 1 \
  --clock \
  --indicator \
  --ignore-empty-password \
  --show-failed-attempts \
  --pointer=default \
  --pass-media-keys --pass-screen-keys --pass-volume-keys --pass-power-keys \
  --radius=150 \
  --ring-width=3 \
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
  --inside-color=00000000 --insidever-color=00000000 --insidewrong-color=00000000 \
  --ring-color=00000000 \
  --ringver-color=00000000 \
  --ringwrong-color=00000000 \
  --line-color=00000000 --separator-color=00000000 \
  --keyhl-color="$fg" --bshl-color="${orange}ff" \
  --time-color="$fg" --date-color="$muted" \
  --verif-color="${accent}ff" --wrong-color="${red}ff" --modif-color="${red}ff" \
  --layout-color="$muted"
