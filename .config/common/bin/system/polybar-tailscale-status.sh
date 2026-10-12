#!/usr/bin/env bash
# This script is used to show the Tailscale connection state, and is largely used
# to display a label in polybar. Styled like the nordvpn module.
#
# - Connected:      white network icon + green "[Tailscale 4/6 online]"
#                   (devices online out of all your other devices on the tailnet).
# - Running, but this machine is offline (can't reach the control plane, e.g.
#   because a VPN is rerouting traffic): orange "[Tailscale offline]".
# - Stopped:        bright yellow "[Tailscale off]".
# - Not installed / daemon down: grey "[Tailscale n/a]".
#
# --mini shows just the logo and a short state ("4/6", "off", ...).
# TAILSCALE_CMD can be overridden for testing.

logoOn=$'\ue010'  # all nine dots.
logoOff=$'\ue011' # only the middle row.
tailscale="${TAILSCALE_CMD:-tailscale}"

# %{T6} is "PolybarIcons" (font-5 in fonts.ini): the Tailscale logo (U+E010 on, U+E011 off).
mini=0
[[ "${1:-}" == "--mini" ]] && mini=1

# render ICON COLOUR FULL-TEXT MINI-TEXT
render() {
  if [[ "$mini" == 1 ]]; then echo "%{T6}$1%{T-}  [%{F$2}$4%{F-}]"; else echo "%{T6}$1%{T-}  [%{F$2}$3%{F-}]"; fi
}

json=$(timeout 3 "$tailscale" status --json 2>/dev/null) || json=""
backend=$(jq -r '.BackendState // empty' <<<"$json" 2>/dev/null)

case "$backend" in
  Running)
    if [[ "$(jq -r '.Self.Online // false' <<<"$json")" == "true" ]]; then
      read -r online total < <(jq -r '[.Peer // {} | .[]] | "\([.[] | select(.Online == true)] | length) \(length)"' <<<"$json")
      render "$logoOn" "#50FA7B" "Tailscale ${online}/${total} online" "${online}/${total}"
    else
      render "$logoOff" "#FFB86C" "Tailscale offline" "offline"
    fi
    ;;
  Stopped | NeedsLogin | NoState) render "$logoOff" "#FFE94D" "Tailscale off" "off" ;;
  *) render "$logoOff" "#6272A4" "Tailscale n/a" "n/a" ;;
esac
