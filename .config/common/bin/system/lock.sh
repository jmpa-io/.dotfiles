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
ring="6272a4"
font="FiraCode Nerd Font"
tree="$HOME/tree-v2.png"
[[ -f $tree ]] || tree="$HOME/.dotfiles/.config/common/tree-v2.png"

# background: blurred, Dracula-tinted screenshot with a round tree avatar and
# the ring in the middle. Falls back to plain i3lock blur if scrot/imagemagick
# are missing or fail: the screen must lock either way.
bg="$(mktemp --suffix=.png)"
treeImg="$(mktemp --suffix=.png)"
trap 'rm -f "$bg" "$treeImg"' EXIT

# round avatar from the tree art: square crop around the tree, box-filtered so
# the pixel art stays crisp.
avatar() { # size
  magick "$tree" -crop 252x252+36+0 +repage -filter Box -resize "${1}x${1}" -alpha set \
    \( +clone -alpha transparent -fill white -draw "circle $(($1 / 2)),$(($1 / 2)) $(($1 / 2)),0" \) \
    -compose DstIn -composite "$treeImg"
}

bgArgs=(--blur 12)
if hash magick scrot 2>/dev/null && scrot -o "$bg" 2>/dev/null &&
  read -r w h < <(magick identify -format '%w %h\n' "$bg"); then
  cx=$((w / 2)) cy=$((h / 2))
  # tinted blur, a soft purple glow around the ring, a dark fill inside it, and
  # the tree as a round badge floating above the ring (i3lock draws the ring on
  # top of the image, so nothing may overlap it).
  magick "$bg" -blur 0x12 -fill '#282a3699' -draw "rectangle 0,0 $w,$h" \
    \( -size "${w}x${h}" xc:none -fill none -stroke "#${purple}aa" -strokewidth 10 \
    -draw "circle $cx,$cy $((cx + 132)),$cy" -blur 0x16 \) -composite \
    -fill '#282a36ea' -stroke none -draw "circle $cx,$cy $((cx + 128)),$cy" \
    -fill '#282a36' -stroke "#$purple" -strokewidth 3 \
    -draw "circle $cx,$((cy - 192)) $((cx + 48)),$((cy - 192))" "$bg" &&
    avatar 84 && magick "$bg" "$treeImg" -gravity center -geometry +0-192 -composite "$bg" &&
    magick "$bg" -gravity center -font FiraCode-Nerd-Font-Reg -pointsize 14 -fill "#${muted%ff}" \
      -annotate +0+172 "${USER:-$(id -un)}@${HOSTNAME%%.*}" "$bg" 2>/dev/null &&
    bgArgs=(--image="$bg")
fi

i3lock \
  "${bgArgs[@]}" \
  --time-str="%I:%M %p" \
  --date-str="%A, %-d %B" \
  --screen 1 \
  --clock \
  --indicator \
  --ignore-empty-password \
  --show-failed-attempts \
  --pointer=default \
  --pass-media-keys --pass-screen-keys --pass-volume-keys --pass-power-keys \
  --radius=125 \
  --ring-width=4 \
  --time-font="$font" --date-font="$font" --verif-font="$font" --wrong-font="$font" \
  --time-size=40 \
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
  --time-color="$fg" --date-color="${purple}ff" \
  --verif-color="${cyan}ff" --wrong-color="${red}ff" --modif-color="${red}ff" \
  --layout-color="$muted"
