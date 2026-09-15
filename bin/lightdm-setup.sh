#!/usr/bin/env bash
# Diagnoses and configures LightDM greeter theme + wallpaper on Manjaro/Arch.
#
# Usage:
#   lightdm-setup           — diagnose current state only
#   lightdm-setup --fix     — diagnose + attempt to fix broken config
#
# Requires: sudo (for writing to /etc/lightdm/)

set -e

die()  { echo "error: $1" >&2; exit "${2:-1}"; }
info() { echo "  $1"; }
ok()   { echo "  [ok] $1"; }
warn() { echo "  [!!] $1"; }
hdr()  { echo ""; echo "── $1 ──"; }

FIX=0
[[ "${1:-}" == "--fix" ]] && FIX=1

[[ "$(uname)" == "Linux" ]] || die "this script is Linux only."

# ── LightDM service ──────────────────────────────────────────────────────────

hdr "LightDM service"
if systemctl is-active --quiet lightdm; then
  ok "lightdm.service is active"
else
  warn "lightdm.service is NOT active"
  systemctl status lightdm --no-pager 2>/dev/null | tail -5 || true
fi

# ── Main config ───────────────────────────────────────────────────────────────

hdr "LightDM config (/etc/lightdm/lightdm.conf)"
LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
if [[ -f "$LIGHTDM_CONF" ]]; then
  ok "found $LIGHTDM_CONF"
  GREETER_SESSION=$(grep -E '^\s*greeter-session\s*=' "$LIGHTDM_CONF" 2>/dev/null | awk -F'=' '{print $2}' | tr -d ' ')
  if [[ -n "$GREETER_SESSION" ]]; then
    ok "greeter-session = $GREETER_SESSION"
  else
    warn "greeter-session not set in $LIGHTDM_CONF"
    GREETER_SESSION=""
  fi
else
  warn "$LIGHTDM_CONF not found"
fi

# ── Detect installed greeter ──────────────────────────────────────────────────

hdr "Installed greeters"
GREETER_CONF=""
for g in slick-greeter lightdm-gtk-greeter webkit2-greeter; do
  if command -v "$g" &>/dev/null || [[ -f "/usr/bin/$g" ]]; then
    ok "$g is installed"
  fi
done

# Determine which greeter config to use.
if [[ -n "$GREETER_SESSION" ]]; then
  case "$GREETER_SESSION" in
    *slick*)   GREETER_CONF="/etc/lightdm/slick-greeter.conf" ;;
    *gtk*)     GREETER_CONF="/etc/lightdm/lightdm-gtk-greeter.conf" ;;
    *webkit*)  GREETER_CONF="/etc/lightdm/lightdm-webkit2-greeter.conf" ;;
  esac
fi

# Fall back to whichever config file exists.
if [[ -z "$GREETER_CONF" ]]; then
  for f in /etc/lightdm/slick-greeter.conf \
            /etc/lightdm/lightdm-gtk-greeter.conf \
            /etc/lightdm/lightdm-webkit2-greeter.conf; do
    [[ -f "$f" ]] && { GREETER_CONF="$f"; break; }
  done
fi

# ── Greeter config ────────────────────────────────────────────────────────────

hdr "Greeter config ($GREETER_CONF)"
if [[ -n "$GREETER_CONF" && -f "$GREETER_CONF" ]]; then
  ok "found $GREETER_CONF"

  BG=$(grep -E '^\s*background\s*=' "$GREETER_CONF" 2>/dev/null | awk -F'=' '{print $2}' | tr -d ' ')
  THEME=$(grep -E '^\s*theme-name\s*=' "$GREETER_CONF" 2>/dev/null | awk -F'=' '{print $2}' | tr -d ' ')
  ICON_THEME=$(grep -E '^\s*icon-theme-name\s*=' "$GREETER_CONF" 2>/dev/null | awk -F'=' '{print $2}' | tr -d ' ')
  FONT=$(grep -E '^\s*font-name\s*=' "$GREETER_CONF" 2>/dev/null | awk -F'=' '{print $2}' | tr -d ' ')

  echo ""
  echo "  background    = ${BG:-(not set)}"
  echo "  theme-name    = ${THEME:-(not set)}"
  echo "  icon-theme    = ${ICON_THEME:-(not set)}"
  echo "  font-name     = ${FONT:-(not set)}"

  # Check wallpaper path exists.
  echo ""
  if [[ -n "$BG" ]]; then
    if [[ -f "$BG" ]]; then
      ok "wallpaper file exists: $BG"
    else
      warn "wallpaper file MISSING: $BG"
      warn "this is likely why your login screen lost its background."
    fi
  else
    warn "no background set in greeter config"
  fi

  # Check GTK theme exists.
  if [[ -n "$THEME" ]]; then
    THEME_FOUND=0
    for d in "/usr/share/themes/$THEME" "$HOME/.themes/$THEME" "$HOME/.local/share/themes/$THEME"; do
      [[ -d "$d" ]] && { ok "GTK theme found: $d"; THEME_FOUND=1; break; }
    done
    [[ "$THEME_FOUND" -eq 0 ]] && warn "GTK theme '$THEME' not found — may have been removed in update"
  fi

else
  warn "no greeter config file found"
fi

# ── Available wallpapers ──────────────────────────────────────────────────────

hdr "Available wallpapers"
WALLPAPER_DIRS=(/usr/share/backgrounds /usr/share/pixmaps "$HOME/.dotfiles/wallpapers")
for d in "${WALLPAPER_DIRS[@]}"; do
  if [[ -d "$d" ]]; then
    count=$(find "$d" -maxdepth 2 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) 2>/dev/null | wc -l)
    info "$d — $count image(s)"
  else
    info "$d — not found"
  fi
done

# ── Fix ───────────────────────────────────────────────────────────────────────

if [[ "$FIX" -eq 1 ]]; then
  hdr "Fixing"

  [[ -z "$GREETER_CONF" ]] && die "cannot fix — no greeter config file found"
  [[ "$(id -u)" -ne 0 ]] && die "run with sudo to apply fixes: sudo $0 --fix"

  # Find a fallback wallpaper if the current one is missing.
  if [[ -z "$BG" || ! -f "$BG" ]]; then
    FALLBACK=""
    for d in /usr/share/backgrounds /usr/share/pixmaps "$HOME/.dotfiles/wallpapers"; do
      FALLBACK=$(find "$d" -maxdepth 2 -type f \( -name "*.jpg" -o -name "*.png" \) 2>/dev/null | head -1)
      [[ -n "$FALLBACK" ]] && break
    done

    if [[ -n "$FALLBACK" ]]; then
      # Backup greeter config.
      cp "$GREETER_CONF" "${GREETER_CONF}.bak"
      info "backed up $GREETER_CONF -> ${GREETER_CONF}.bak"

      if grep -qE '^\s*background\s*=' "$GREETER_CONF"; then
        sed -i "s|^\s*background\s*=.*|background=$FALLBACK|" "$GREETER_CONF"
      else
        echo "background=$FALLBACK" >> "$GREETER_CONF"
      fi
      ok "set background = $FALLBACK"
    else
      warn "no fallback wallpaper found — add one to ~/.dotfiles/wallpapers/ and re-run"
    fi
  else
    ok "wallpaper path is valid — nothing to fix"
  fi

  echo ""
  echo "done. changes take effect on next login / lightdm restart."
  echo "to restart lightdm (will end your current session): sudo systemctl restart lightdm"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

if [[ "$FIX" -eq 0 ]]; then
  echo ""
  echo "run with --fix to attempt automatic repair: sudo $0 --fix"
fi
echo ""
