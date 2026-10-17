#!/usr/bin/env bash
# This script is used to warn about pam_faillock lockouts, and is largely used
# to display a label in polybar. Prints nothing when there is nothing to warn
# about (no recent failed logins).
#
# - Failures counting toward a lockout:  yellow "failed logins n/deny".
# - Locked out:                          red "LOCKED OUT" with seconds left.
#
# Reads deny/unlock_time from /etc/security/faillock.conf (defaults 3 / 600).
# FAILLOCK_CMD and NOW can be overridden for testing.

conf="/etc/security/faillock.conf"
deny=3
unlock=600
if [[ -r "$conf" ]]; then
  v=$(sed -nE 's/^[[:space:]]*deny[[:space:]]*=[[:space:]]*([0-9]+).*/\1/p' "$conf" | tail -1)
  [[ -n "$v" ]] && deny="$v"
  v=$(sed -nE 's/^[[:space:]]*unlock_time[[:space:]]*=[[:space:]]*([0-9]+).*/\1/p' "$conf" | tail -1)
  [[ -n "$v" ]] && unlock="$v"
fi

# Count the valid failures, and note when the most recent one happened.
read -r count last < <(
  ${FAILLOCK_CMD:-faillock} --user "${USER:-$(id -un)}" 2>/dev/null |
    awk 'NR > 1 && $NF == "V" { n++; ts = $1 " " $2 } END { print n + 0, "|" ts }'
)
last="${last#|}"
[[ "${count:-0}" -eq 0 ]] && exit 0

# Locked out? Show the time left, otherwise show how close we are.
if [[ "$count" -ge "$deny" && -n "$last" ]]; then
  now="${NOW:-$(date +%s)}"
  lastEpoch=$(date -d "$last" +%s 2>/dev/null) || exit 0
  remaining=$((unlock - (now - lastEpoch)))
  if [[ "$remaining" -gt 0 ]]; then
    echo "%{F#E07E7E}🔒 LOCKED OUT ${remaining}s%{F-} "
    exit 0
  fi
fi
echo "%{F#E0C97E}⚠ failed logins ${count}/${deny}%{F-} "
