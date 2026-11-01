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

# background: blurred, Dracula-tinted screenshot with a soft purple glow and a
# dark fill behind the ring. Falls back to plain i3lock blur if scrot/imagemagick
# are missing or fail: the screen must lock either way.
bg="$(mktemp --suffix=.png)"
trap 'rm -f "$bg"' EXIT

bgArgs=(--blur 12)
if hash magick scrot 2>/dev/null && scrot -o "$bg" 2>/dev/null &&
  read -r w h < <(magick identify -format '%w %h\n' "$bg"); then
  cx=$((w / 2)) cy=$((h / 2))
  # Symmetric, odd-width lines so per-line centring lines up. No backslashes
  # (-annotate eats them) and no runs of '-' or '=' (Fira Code ligatures).
  logo="$(
    cat <<'LOGO'
,___,
( ._. )
|     |
._________.
|         |
|    O    |
|    |    |
'_________'
LOGO
  )"
  details="$(printf '%s@%s\nlocked %s\nup %s' "${USER:-$(id -un)}" "${HOSTNAME%%.*}" \
    "$(date '+%H:%M')" "$(uptime -p 2>/dev/null | sed 's/^up //')")"
  magick "$bg" -blur 0x12 -fill '#282a3699' -draw "rectangle 0,0 $w,$h" \
    \( -size "${w}x${h}" xc:none -fill none -stroke "#${purple}aa" -strokewidth 14 \
    -draw "circle $cx,$cy $((cx + 200)),$cy" -blur 0x20 \) -composite \
    -fill '#282a36ea' -stroke none -draw "circle $cx,$cy $((cx + 194)),$cy" "$bg" &&
    magick "$bg" -gravity center -font FiraCode-Nerd-Font-Reg -interline-spacing 0 \
      -pointsize 16 -fill "#${purple}" -annotate +0-295 "$logo" \
      -pointsize 16 -fill "#${muted%ff}" -annotate +0+265 "$details" "$bg" 2>/dev/null &&
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
  --pointer=default \
  --pass-media-keys --pass-screen-keys --pass-volume-keys --pass-power-keys \
  --radius=190 \
  --ring-width=14 \
  --time-font="$font" --date-font="$font" --verif-font="$font" --wrong-font="$font" \
  --time-size=68 \
  --date-size=26 \
  --verif-size=22 \
  --wrong-size=22 \
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
