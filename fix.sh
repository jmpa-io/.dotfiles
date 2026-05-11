#!/usr/bin/env bash
# fix.sh - applies dotfile fixes + dumps diagnostics for debugging.
# Run on the machine where you want fixes applied:
#   bash fix.sh
# To push diagnostics back for review:
#   git add dist/diagnostics.txt && git commit -m "diag: diagnostics" && git push
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
WEZTERM_CONFIG="$DOTFILES/.config/wezterm/.wezterm.lua"
PICOM_CONFIG="$DOTFILES/.config/picom/picom.conf"
POLYBAR_FONTS="$DOTFILES/.config/polybar/fonts.ini"
DIAG="$DOTFILES/dist/diagnostics.txt"

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
# Fix 1: polybar — font-0 (FiraCode Nerd Font)
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
# Fix 2: WezTerm — prefer_egl (flx-no-stencil equivalent)
# ─────────────────────────────────────────────────────────────────────────────
echo "--> Fix 2: WezTerm front_end + prefer_egl"

if [[ ! -f "$WEZTERM_CONFIG" ]]; then
  warn "WezTerm config not found — skipping"
elif grep -q "prefer_egl" "$WEZTERM_CONFIG"; then
  ok "prefer_egl already set — skipping"
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
# Fix 3: picom — remove stale config files + ensure vsync is enabled
#
# Picom searches for config in this order:
#   1. ~/.config/picom/picom.conf  (dotfiles — correct)
#   2. ~/.config/picom.conf        (stale old file — REMOVE THIS)
#   3. /etc/xdg/picom.conf         (system default — ignore)
#
# The stale ~/.config/picom.conf is what causes deprecated option warnings
# when running picom bare from the terminal.
# ─────────────────────────────────────────────────────────────────────────────
echo "--> Fix 3: picom — remove stale config + deprecated options + vsync"

# Remove stale ~/.config/picom.conf if it exists (not a directory/symlink).
STALE_PICOM="$HOME/.config/picom.conf"
if [[ -f "$STALE_PICOM" ]] && [[ ! -L "$STALE_PICOM" ]]; then
  backup "$STALE_PICOM"
  rm "$STALE_PICOM"
  ok "removed stale ~/.config/picom.conf"
elif [[ ! -e "$STALE_PICOM" ]]; then
  ok "no stale ~/.config/picom.conf found"
fi

LIVE_PICOM="$HOME/.config/picom/picom.conf"

if [[ ! -e "$LIVE_PICOM" ]]; then
  warn "picom config not found at $LIVE_PICOM — skipping"
else
  TMP="$(mktemp /tmp/picom.XXXXXX)"
  DEPRECATED='^\s*(refresh-rate|glx-no-stencil|glx-copy-from-front|glx-swap-method|dbe|sw-opti)\s*='

  cat "$LIVE_PICOM" \
    | grep -Ev "$DEPRECATED" \
    | sed 's/^vsync = false;/vsync = true;/' \
    > "$TMP"

  if ! diff -q "$LIVE_PICOM" "$TMP" > /dev/null 2>&1; then
    # Write to the dotfiles source (not through the symlink chain).
    cp "$TMP" "$PICOM_CONFIG"
    ok "picom.conf updated — deprecated options removed, vsync enabled"
  else
    ok "picom.conf already clean"
  fi
  rm -f "$TMP"
fi
echo

# ─────────────────────────────────────────────────────────────────────────────
# Fix 4: polybar — Noto Color Emoji font-4
# ─────────────────────────────────────────────────────────────────────────────
echo "--> Fix 4: polybar emoji font (Noto Color Emoji)"

if [[ ! -f "$POLYBAR_FONTS" ]]; then
  warn "polybar fonts.ini not found — skipping"
elif grep -q "Noto Color Emoji" "$POLYBAR_FONTS"; then
  ok "Noto Color Emoji already present"
else
  backup "$POLYBAR_FONTS"
  printf '\n# emoji fallback — same offset as other fonts.\nfont-4 = "Noto Color Emoji:scale=10;2"\n' >> "$POLYBAR_FONTS"
  ok "added Noto Color Emoji as font-4"
fi
echo

# ─────────────────────────────────────────────────────────────────────────────
# Diagnostics — dump current state to dist/diagnostics.txt
# Commit and push this file so it can be reviewed remotely.
# ─────────────────────────────────────────────────────────────────────────────
echo "--> Diagnostics"

mkdir -p "$DOTFILES/dist"

{
  echo "=== diagnostics: $(date) ==="
  echo "=== hostname: $(hostname) ==="
  echo ""

  echo "--- picom.conf (live) ---"
  cat "$LIVE_PICOM" 2>/dev/null || echo "NOT FOUND"
  echo ""

  echo "--- picom.conf symlink info ---"
  ls -la "$HOME/.config/picom/picom.conf" 2>/dev/null || echo "NOT FOUND"
  ls -la "$HOME/.config/picom" 2>/dev/null || echo "DIR NOT FOUND"
  echo ""

  echo "--- polybar/fonts.ini ---"
  cat "$POLYBAR_FONTS" 2>/dev/null || echo "NOT FOUND"
  echo ""

  echo "--- polybar/modules/pulseaudio.ini ---"
  cat "$DOTFILES/.config/polybar/modules/pulseaudio.ini" 2>/dev/null || echo "NOT FOUND"
  echo ""

  echo "--- installed fonts (nerd/fira/awesome/noto) ---"
  fc-list 2>/dev/null | grep -i "nerd\|fira\|awesome\|noto.color" | sort || echo "fc-list failed"
  echo ""

  echo "--- picom version ---"
  picom --version 2>/dev/null || echo "picom not found"
  echo ""

  echo "--- polybar version ---"
  polybar --version 2>/dev/null || echo "polybar not found"
  echo ""

  echo "--- picom log (last 30 lines) ---"
  journalctl --user -u picom -n 30 --no-pager 2>/dev/null \
    || cat /tmp/picom-fix.log 2>/dev/null \
    || cat "$HOME/.local/share/picom.log" 2>/dev/null \
    || echo "no picom log found"
  echo ""

  echo "--- picom config search path ---"
  echo "~/.config/picom/picom.conf:"
  ls -la "$HOME/.config/picom/picom.conf" 2>/dev/null || echo "NOT FOUND"
  echo "~/.config/picom.conf:"
  ls -la "$HOME/.config/picom.conf" 2>/dev/null || echo "NOT FOUND"
  echo "/etc/xdg/picom.conf:"
  ls -la /etc/xdg/picom.conf 2>/dev/null || echo "NOT FOUND"
  echo ""

  echo "--- picom stderr (run directly to capture warnings) ---"
  timeout 3 picom --no-daemon 2>&1 | head -40 || true
  echo ""

  echo "--- polybar log (last 30 lines) ---"
  journalctl --user -u polybar -n 30 --no-pager 2>/dev/null \
    || cat "$HOME/.local/share/polybar/polybar.log" 2>/dev/null \
    || cat /tmp/polybar.log 2>/dev/null \
    || echo "no polybar log found"
  echo ""

  echo "--- all polybar module files ---"
  for f in "$DOTFILES/.config/polybar/modules/"*.ini; do
    echo "=== $(basename "$f") ==="
    cat "$f"
    echo ""
  done

} > "$DIAG"

ok "diagnostics written to dist/diagnostics.txt"
echo "    commit and push to share: git add dist/diagnostics.txt && git commit -m 'diag: diagnostics' && git push"
echo

# ─────────────────────────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────────────────────────
echo "==> all fixes applied."
echo "    Restarting picom..."
pkill -x picom 2>/dev/null || true
sleep 1
picom -b --log-level=warn --log-file=/tmp/picom-fix.log 2>/dev/null
ok "picom restarted — log at /tmp/picom-fix.log"
echo "    Restart polybar to pick up font/module changes:"
echo "      ~/.config/polybar/launch.sh"
echo
