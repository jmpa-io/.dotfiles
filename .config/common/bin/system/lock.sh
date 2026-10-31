#!/usr/bin/env bash
# uses i3lock to lock the screen on this machine.

hash i3lock 2>/dev/null || {
  echo "missing i3lock"
  exit 1
}

# colors: Dracula, same palette as polybar, rofi and dunst.
fg="f8f8f2ff"
muted="6272a4ff"
purple="bd93f9"
pink="ff79c6"
cyan="8be9fd"
orange="ffb86c"
red="ff5555"
ring="44475a"
font="FiraCode Nerd Font"
tree="$HOME/tree-v2.png"
[[ -f $tree ]] || tree="$HOME/.dotfiles/.config/common/tree-v2.png"

# background: blurred, Dracula-tinted screenshot with a squircle card
# (|x|^n + |y|^n = 1) in the middle, bordered like rofi/dunst, with the
# terminal's tree on top. Falls back to plain i3lock blur if scrot/imagemagick/awk
# are missing or fail: the screen must lock either way.
bg="$(mktemp --suffix=.png)"
trap 'rm -f "$bg"' EXIT
bgArgs=(--blur 12)
if hash scrot magick awk 2>/dev/null && scrot -o "$bg" 2>/dev/null &&
  read -r w h < <(magick identify -format '%w %h\n' "$bg"); then
  points=$(awk -v cx=$((w / 2)) -v cy=$((h / 2)) -v r=255 -v n=6 'BEGIN {
    for (i = 0; i < 160; i++) {
      t = 2 * 3.14159265 * i / 160; c = cos(t); s = sin(t)
      x = (c < 0 ? -1 : 1) * (c < 0 ? -c : c) ^ (2 / n)
      y = (s < 0 ? -1 : 1) * (s < 0 ? -s : s) ^ (2 / n)
      printf "%.1f,%.1f ", cx + r * x, cy + r * y
    }
  }')
  if magick "$bg" -blur 0x12 -fill '#282a3699' -draw "rectangle 0,0 $w,$h" \
    -fill '#282a36f2' -stroke "#$purple" -strokewidth 3 -draw "polygon $points" "$bg"; then
    bgArgs=(--image="$bg")
    [[ -f $tree ]] &&
      magick "$bg" \( "$tree" -resize 88x \) -gravity center -geometry +0-200 -composite "$bg"
    magick "$bg" -gravity center -font FiraCode-Nerd-Font-Reg -pointsize 16 -fill "#${muted%ff}" \
      -annotate +0+215 "${USER:-$(id -un)}@${HOSTNAME%%.*}" "$bg" 2>/dev/null
  fi
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
  --time-font="$font" --date-font="$font" --verif-font="$font" --wrong-font="$font" \
  --time-size=48 \
  --date-size=16 \
  --verif-size=16 \
  --wrong-size=16 \
  --greeter-text="" \
  --verif-text="Verifying..." \
  --wrong-text="Incorrect password" \
  --noinput="Enter your password" \
  --lock-text="Locking..." \
  --lockfailed-text="Locking failed" \
  --inside-color=00000000 --insidever-color=00000000 --insidewrong-color=00000000 \
  --ring-color="${ring}ff" \
  --ringver-color="${cyan}ff" \
  --ringwrong-color="${red}ff" \
  --line-color=00000000 --separator-color=00000000 \
  --keyhl-color="${pink}ff" --bshl-color="${orange}ff" \
  --time-color="$fg" --date-color="$muted" \
  --verif-color="${cyan}ff" --wrong-color="${red}ff" --modif-color="${red}ff" \
  --layout-color="$muted"
