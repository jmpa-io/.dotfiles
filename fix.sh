#!/usr/bin/env bash
# fix.sh - applies dotfile fixes to the current machine.
# Run on any machine after cloning the dotfiles repo:
#   bash ~/.dotfiles/fix.sh
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
WEZTERM_CONFIG="$DOTFILES/.config/wezterm/.wezterm.lua"
PICOM_CONFIG="$DOTFILES/.config/picom/picom.conf"
POLYBAR_FONTS="$DOTFILES/.config/polybar/fonts.ini"

ok()   { printf '\033[32m  ok\033[0m  %s\n' "$*"; }
info() { printf '\033[34minfo\033[0m  %s\n' "$*"; }
warn() { printf '\033[33mwarn\033[0m  %s\n' "$*"; }

backup() {
  local file="$1"
  local bak="${file}.bak.$(date +%Y%m%d%H%M%S)"
  cp "$file" "$bak"
  info "backed up $(basename "$file") -> $(basename "$bak")"
}

echo
echo "==> dotfiles fix script"
echo "    DOTFILES=$DOTFILES"
echo

# ─────────────────────────────────────────────────────────────────────────────
# Fix 1: polybar — verify FiraCode Nerd Font is set as font-0
# ─────────────────────────────────────────────────────────────────────────────
echo "--> Fix 1: polybar font-0 (FiraCode Nerd Font)"

if [[ ! -f "$POLYBAR_FONTS" ]]; then
  warn "polybar fonts.ini not found — skipping"
elif grep -q '"FiraCode Nerd Font:' "$POLYBAR_FONTS"; then
  ok "font-0 is already set to FiraCode Nerd Font"
else
  backup "$POLYBAR_FONTS"
  sed -i 's|"FiraCode:pixelsize|"FiraCode Nerd Font:pixelsize|' "$POLYBAR_FONTS"
  ok "updated font-0 to FiraCode Nerd Font"
fi
echo

# ─────────────────────────────────────────────────────────────────────────────
# Fix 2: WezTerm — prefer_egl to avoid GPU stencil buffer issues
# ─────────────────────────────────────────────────────────────────────────────
echo "--> Fix 2: WezTerm prefer_egl"

if [[ ! -f "$WEZTERM_CONFIG" ]]; then
  warn "WezTerm config not found — skipping"
elif grep -q "prefer_egl" "$WEZTERM_CONFIG"; then
  ok "prefer_egl already set"
else
  backup "$WEZTERM_CONFIG"
  perl -i -pe '
    if (/^return config/) {
      print "-- Workaround for stencil buffer issues (equivalent to --flx-no-stencil CLI flag).\n";
      print "config.front_end = \"OpenGL\"\n";
      print "config.prefer_egl = true\n\n";
    }
  ' "$WEZTERM_CONFIG"
  ok "added prefer_egl = true + front_end = OpenGL"
fi
echo

# ─────────────────────────────────────────────────────────────────────────────
# Fix 3: picom — remove stale ~/.config/picom.conf
#
# Picom searches: ~/.config/picom/picom.conf first, then ~/.config/picom.conf.
# The stale file at ~/.config/picom.conf (if it exists) contains deprecated
# options and takes priority when running picom bare from the terminal.
# ─────────────────────────────────────────────────────────────────────────────
echo "--> Fix 3: picom — remove stale config"

STALE_PICOM="$HOME/.config/picom.conf"
if [[ -f "$STALE_PICOM" ]] && [[ ! -L "$STALE_PICOM" ]]; then
  backup "$STALE_PICOM"
  rm "$STALE_PICOM"
  ok "removed stale ~/.config/picom.conf"
else
  ok "no stale ~/.config/picom.conf found"
fi

# Also strip any remaining deprecated options from the live config.
LIVE_PICOM="$HOME/.config/picom/picom.conf"
if [[ -e "$LIVE_PICOM" ]]; then
  TMP="$(mktemp /tmp/picom.XXXXXX)"
  DEPRECATED='^\s*(refresh-rate|glx-no-stencil|glx-copy-from-front|glx-swap-method|dbe|sw-opti)\s*='
  cat "$LIVE_PICOM" \
    | grep -Ev "$DEPRECATED" \
    | sed 's/^vsync = false;/vsync = true;/' \
    > "$TMP"
  if ! diff -q "$LIVE_PICOM" "$TMP" > /dev/null 2>&1; then
    cp "$TMP" "$PICOM_CONFIG"
    ok "stripped deprecated options from picom.conf"
  else
    ok "picom.conf already clean"
  fi
  rm -f "$TMP"

  # Restart picom with the clean config.
  pkill -x picom 2>/dev/null || true
  sleep 1
  picom -b --config "$LIVE_PICOM" 2>/dev/null
  ok "picom restarted"
fi
echo

# ─────────────────────────────────────────────────────────────────────────────
# Fix 4: polybar — ensure Noto Color Emoji is present as font-4
# ─────────────────────────────────────────────────────────────────────────────
echo "--> Fix 4: polybar Noto Color Emoji font"

if [[ ! -f "$POLYBAR_FONTS" ]]; then
  warn "polybar fonts.ini not found — skipping"
elif grep -q "Noto Color Emoji" "$POLYBAR_FONTS"; then
  ok "Noto Color Emoji already present"
else
  backup "$POLYBAR_FONTS"
  printf '\n# emoji fallback — same offset as other fonts.\nfont-4 = "Noto Color Emoji:scale=10;0"\n' >> "$POLYBAR_FONTS"
  ok "added Noto Color Emoji as font-4"
fi
echo

# ─────────────────────────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────────────────────────
echo "==> all fixes applied."
echo "    Restart polybar to pick up any font/module changes:"
echo "      ~/.config/polybar/launch.sh"
echo
