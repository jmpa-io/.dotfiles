#!/usr/bin/env bash
# This script is used to turn Tailscale on or off with a click in polybar.
# It asks first with a rofi prompt, then uses polkit (a graphical password
# prompt) because `tailscale up/down` needs root. Sends a notification after.
#
# TAILSCALE_CMD, ROFI_CMD, PRIV_CMD and NOTIFY_CMD can be overridden for testing.

tailscale="${TAILSCALE_CMD:-tailscale}"
rofi="${ROFI_CMD:-rofi}"
priv="${PRIV_CMD:-pkexec}"
notify="${NOTIFY_CMD:-notify-send}"

backend=$(timeout 3 "$tailscale" status --json 2>/dev/null | jq -r '.BackendState // empty')
if [[ -z "$backend" ]]; then
  "$notify" "Tailscale" "Tailscale daemon isn't running (systemctl status tailscaled)"
  exit 1
fi

if [[ "$backend" == "Running" ]]; then
  action=down
  question="Turn Tailscale OFF?"
else
  action=up
  question="Turn Tailscale ON?"
fi

answer=$(printf 'Yes\nNo\n' | "$rofi" -dmenu -i -p "$question" -no-custom -l 2) || exit 0
[[ "$answer" == "Yes" ]] || exit 0

out=$("$priv" "$tailscale" "$action" 2>&1)
"$notify" "Tailscale" "$(tr -d '\r' <<<"${out:-Tailscale ${action}: done}" | tail -1)"
