#!/usr/bin/env bash
# fix.sh - applies dotfile fixes to the current machine
# Run this on the machine where you want the fixes applied.
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
WEZTERM_CONFIG="$DOTFILES/.config/wezterm/.wezterm.lua"
PICOM_CONFIG="$DOTFILES/.config/picom/picom.conf"

ok()   { printf '\033[32m  ok\033[0m  %s\n' "$*"; }
info() { printf '\033[34minfo\033[0m  %s\n' "$*"; }
warn() { printf '\033[33mwarn\033[0m  %s\n' "$*"; }
fail() { printf '\033[31mfail\033[0m  %s\n' "$*" >&2; exit 1; }

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
# Fix 1: polybar — font-0 was 'FiraCode' (no icons/emoji) instead of
# 'FiraCode Nerd Font'. The plain Fira Code family doesn't include Nerd Font
# glyphs, so all icons in modules (Font Awesome, nerd symbols) would either
# show as boxes or fall through to the wrong fallback font.
# This is now baked into fonts.ini — this step just verifies it landed.
# ─────────────────────────────────────────────────────────────────────────────
echo "--> Fix 1: polybar font-0 (FiraCode Nerd Font)"

POLYBAR_FONTS="$DOTFILES/.config/polybar/fonts.ini"
if [[ ! -f "$POLYBAR_FONTS" ]]; then
  warn "polybar fonts.ini not found at $POLYBAR_FONTS — skipping"
elif grep -q '"FiraCode Nerd Font:' "$POLYBAR_FONTS"; then
  ok "font-0 is already set to FiraCode Nerd Font"
else
  backup "$POLYBAR_FONTS"
  sed -i 's|"FiraCode:pixelsize|"FiraCode Nerd Font:pixelsize|' "$POLYBAR_FONTS"
  ok "updated font-0 to FiraCode Nerd Font in fonts.ini"
fi
echo

# ─────────────────────────────────────────────────────────────────────────────
# Fix 2: WezTerm — flx-no-stencil / GPU stencil buffer issue
#
# --flx-no-stencil is a wezterm CLI flag that disables stencil buffer use in
# the OpenGL front-end. The config equivalent is setting front_end to
# 'OpenGL' with prefer_egl = true, which avoids the stencil path on drivers
# that report it incorrectly. If you were passing --flx-no-stencil on the
# command line, this bakes it permanently into your config.
# ─────────────────────────────────────────────────────────────────────────────
echo "--> Fix 2: WezTerm front_end + prefer_egl (flx-no-stencil)"

if [[ ! -f "$WEZTERM_CONFIG" ]]; then
  warn "WezTerm config not found at $WEZTERM_CONFIG — skipping"
else
  if grep -q "prefer_egl" "$WEZTERM_CONFIG"; then
    ok "prefer_egl already set — skipping"
  else
    backup "$WEZTERM_CONFIG"
    # Insert prefer_egl and front_end before the final 'return config' line.
    # This is the config-file equivalent of passing --flx-no-stencil.
    perl -i -pe '
      if (/^return config/) {
        print "-- Workaround for stencil buffer issues (equivalent to --flx-no-stencil CLI flag).\n";
        print "-- Switches to EGL surface creation which avoids the broken stencil path on some drivers.\n";
        print "config.front_end = \"OpenGL\"\n";
        print "config.prefer_egl = true\n";
        print "\n";
      }
    ' "$WEZTERM_CONFIG"
    ok "added prefer_egl = true + front_end = OpenGL to .wezterm.lua"
  fi
fi
echo

# ─────────────────────────────────────────────────────────────────────────────
# Fix 3: picom — refresh-rate is deprecated in modern picom
#
# The old 'refresh-rate' option was removed from picom after the fork from
# compton. The config already has it commented out correctly. However vsync
# is set to false which can cause tearing. This fix enables vsync.
#
# Note: if you are on nvidia with the proprietary driver, vsync = true with
# the glx backend can sometimes cause issues. If you see freezes after this
# fix, set vsync back to false and add 'glx-swap-method = 1;' instead.
# ─────────────────────────────────────────────────────────────────────────────
echo "--> Fix 3: picom vsync (refresh-rate deprecation)"

if [[ ! -f "$PICOM_CONFIG" ]]; then
  warn "picom config not found at $PICOM_CONFIG — skipping"
else
  if grep -q "^vsync = true" "$PICOM_CONFIG"; then
    ok "vsync already enabled — skipping"
  else
    backup "$PICOM_CONFIG"
    sed -i 's/^vsync = false;/vsync = true;/' "$PICOM_CONFIG"
    ok "set vsync = true in picom.conf"
  fi
fi
echo

# ─────────────────────────────────────────────────────────────────────────────
# Fix 4: polybar — emoji/icon vertical spacing
#
# Font Awesome glyphs and Nerd Font symbols render with offset ;3 to align
# vertically with the FiraCode text. However emoji (Unicode codepoints not
# covered by the above) fall through to the system emoji font and inherit the
# wrong offset, causing them to appear too high or too low relative to text.
# Adding Noto Color Emoji as font-4 with offset ;0 fixes this.
# This is now baked into fonts.ini — this step just verifies it landed.
# ─────────────────────────────────────────────────────────────────────────────
echo "--> Fix 4: polybar emoji vertical spacing (Noto Color Emoji font-4)"

POLYBAR_FONTS="$DOTFILES/.config/polybar/fonts.ini"
if [[ ! -f "$POLYBAR_FONTS" ]]; then
  warn "polybar fonts.ini not found at $POLYBAR_FONTS — skipping"
elif grep -q "Noto Color Emoji" "$POLYBAR_FONTS"; then
  ok "Noto Color Emoji already present in fonts.ini"
else
  backup "$POLYBAR_FONTS"
  printf '\n# emoji fallback — offset 0 prevents vertical misalignment with text.\nfont-4 = "Noto Color Emoji:scale=10;0"\n' >> "$POLYBAR_FONTS"
  ok "added Noto Color Emoji as font-4 in fonts.ini"
fi
echo

# ─────────────────────────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────────────────────────
echo "==> all fixes applied."
echo "    Restart polybar and picom for changes to take effect."
echo "    Backups of modified files are saved alongside originals (.bak.TIMESTAMP)."
echo
