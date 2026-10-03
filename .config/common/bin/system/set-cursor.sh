#!/usr/bin/env bash
# This script applies the cursor theme named in your GTK settings to X, so it
# is consistent in i3. It replaces Manjaro's 'fix_xcursor'. Unlike that script
# it only reads your config files (never edits them), and does nothing if the
# theme isn't installed, so it works the same on Manjaro and Arch Linux.
#
# Usage: set-cursor.sh [theme]    (default: cursor-theme-name from gtk-3.0)

gtk3="$HOME/.config/gtk-3.0/settings.ini"
theme="${1:-$(sed -nE 's/^gtk-cursor-theme-name=//p' "$gtk3" 2>/dev/null | tr -d '"' | head -1)}"
[[ -z "$theme" ]] && exit 0

# only apply a theme that actually exists.
found=""
for d in /usr/share/icons "$HOME/.local/share/icons" "$HOME/.icons"; do
  [[ -d "$d/$theme/cursors" ]] && found=1
done
if [[ -z "$found" ]]; then
  echo "set-cursor: cursor theme '$theme' is not installed; leaving the cursor unchanged" >&2
  exit 0
fi

echo "Xcursor.theme: $theme" | xrdb -merge 2>/dev/null
hash gsettings 2>/dev/null \
  && gsettings set org.gnome.desktop.interface cursor-theme "$theme" 2>/dev/null
exit 0
