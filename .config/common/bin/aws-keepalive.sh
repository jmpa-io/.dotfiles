#!/usr/bin/env bash
# Keeps the AWS SSO session alive by making a cheap authed call on a cron.
#
# The aws cli refreshes the SSO access token itself (using the refresh token
# stored in ~/.aws/sso/cache) whenever it's used, so no browser is needed until
# the SSO client registration expires (~90 days) — then run 'aws login <profile>'.
#
#   aws-keepalive on [profile]   install the cron job (default profile: $AWS_KEEPALIVE_PROFILE or $AWS_PROFILE)
#   aws-keepalive off            remove the cron job
#   aws-keepalive status         show if it's on, when SSO needs a real login, and recent log lines
#   aws-keepalive run            refresh once now (this is what cron runs)
#
# It also warns (once a day) when the SSO registration is close to expiring.
#
# Env: AWS_KEEPALIVE_PROFILE, AWS_KEEPALIVE_INTERVAL (minutes, default 15),
#      AWS_KEEPALIVE_WARN_DAYS (default 7), AWS_KEEPALIVE_LOG (default ~/.aws/keepalive.log).

set -u

# cron's PATH is minimal; append (not prepend) the usual aws cli locations.
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

# vars.
tag="# aws-keepalive"
log="${AWS_KEEPALIVE_LOG:-$HOME/.aws/keepalive.log}"
interval="${AWS_KEEPALIVE_INTERVAL:-15}"
warnDays="${AWS_KEEPALIVE_WARN_DAYS:-7}"
logLines=200

# funcs.
die() {
  echo "$1" >&2
  exit "${2:-1}"
}

# resolves symlinks without 'readlink -f' (not available on stock macOS).
resolve() {
  local p="$1" l
  while [[ -L "$p" ]]; do
    l=$(readlink "$p")
    [[ "$l" == /* ]] && p="$l" || p="$(dirname "$p")/$l"
  done
  echo "$(cd "$(dirname "$p")" && pwd)/$(basename "$p")"
}

# prints the current crontab (empty if there isn't one); dies on any other
# failure so we never write back a truncated crontab.
read_crontab() {
  local out
  if out=$(crontab -l 2>&1); then
    printf '%s\n' "$out"
  elif [[ "$out" == *"no crontab"* ]]; then
    return 0
  else
    die "unable to read crontab: $out"
  fi
}

# current crontab without our entry (grep exits 1 when nothing is left, which is fine).
crontab_without_ours() {
  local current
  current=$(read_crontab) || return 1
  printf '%s\n' "$current" | grep -vF "$tag" || true
}

notify() {
  case "$(uname)" in
  Darwin) osascript -e "display notification \"$2\" with title \"$1\"" 2>/dev/null ;;
  *)
    hash notify-send 2>/dev/null || return 0
    DISPLAY="${DISPLAY:-:0}" \
      DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}" \
      notify-send "$1" "$2" 2>/dev/null
    ;;
  esac
  return 0
}

# the unix time the SSO client registration expires (empty if unknown); after
# this a browser login is needed. Needs jq; silently unknown without it.
registration_expiry() {
  hash jq 2>/dev/null || return 0
  jq -r 'select(.refreshToken and .registrationExpiresAt) | .registrationExpiresAt | fromdateiso8601' \
    ~/.aws/sso/cache/*.json 2>/dev/null | sort -n | tail -n1
}

# formats a unix time (GNU date, then BSD date).
format_time() { date -d "@$1" '+%Y-%m-%d' 2>/dev/null || date -r "$1" '+%Y-%m-%d'; }

# notifies at most once a day when the registration is within $warnDays of expiring.
warn_if_expiring() {
  local profile="$1" exp now days today stamp="$log.warned"
  exp=$(registration_expiry)
  [[ -n "$exp" ]] || return 0
  now=$(date +%s)
  days=$(((exp - now) / 86400))
  ((days <= warnDays)) || return 0
  today=$(date +%F)
  [[ -f "$stamp" && "$(cat "$stamp")" == "$today" ]] && return 0
  echo "$today" >"$stamp"
  echo "$(date '+%Y-%m-%dT%H:%M:%S%z') warn sso registration expires in ${days}d ($(format_time "$exp"))" >>"$log"
  notify "AWS SSO login needed soon" "Expires in ${days}d; run: aws login $profile"
}

cmd_on() {
  local profile="${1:-${AWS_KEEPALIVE_PROFILE:-${AWS_PROFILE:-}}}" self
  [[ -n "$profile" ]] || die "no profile; usage: aws-keepalive on <profile>"
  [[ "$profile" =~ ^[A-Za-z0-9._-]+$ ]] || die "invalid profile name: $profile"
  if ! [[ "$interval" =~ ^[0-9]+$ ]] || ((interval < 1 || interval > 59)); then
    die "AWS_KEEPALIVE_INTERVAL must be 1-59 minutes, got: $interval"
  fi
  hash crontab 2>/dev/null || die "missing dep: crontab"
  self=$(resolve "${BASH_SOURCE[0]}")
  [[ "$self" =~ ^[A-Za-z0-9._/+-]+$ ]] || die "script path has characters cron can't handle: $self"

  local current
  current=$(crontab_without_ours) || exit 1
  {
    [[ -n "$current" ]] && printf '%s\n' "$current"
    echo "*/$interval * * * * AWS_KEEPALIVE_PROFILE=$profile $self run $tag"
  } | crontab - || die "unable to write crontab"
  echo "on: refreshing '$profile' every $interval min"
}

cmd_off() {
  hash crontab 2>/dev/null || die "missing dep: crontab"
  local current
  current=$(crontab_without_ours) || exit 1
  if [[ -n "$current" ]]; then
    printf '%s\n' "$current" | crontab - || die "unable to write crontab"
  else
    crontab -r 2>/dev/null
  fi
  echo "off"
}

cmd_status() {
  local entry exp
  entry=$(read_crontab | grep -F "$tag")
  if [[ -n "$entry" ]]; then echo "on: $entry"; else echo "off"; fi
  exp=$(registration_expiry)
  [[ -n "$exp" ]] && echo "sso registration expires: $(format_time "$exp") (then run 'aws login <profile>')"
  [[ -f "$log" ]] && tail -n 5 "$log"
  return 0
}

cmd_run() {
  local profile="${AWS_KEEPALIVE_PROFILE:-${AWS_PROFILE:-}}" out prev=""
  [[ -n "$profile" ]] || die "no profile; set AWS_KEEPALIVE_PROFILE"
  hash aws 2>/dev/null || die "missing dep: aws"
  mkdir -p "$(dirname "$log")"
  [[ -f "$log" ]] && prev=$(tail -n1 "$log")

  if out=$(aws sts get-caller-identity --profile "$profile" --query Arn --output text 2>&1); then
    echo "$(date '+%Y-%m-%dT%H:%M:%S%z') ok $out" >>"$log"
    warn_if_expiring "$profile"
  else
    echo "$(date '+%Y-%m-%dT%H:%M:%S%z') FAIL ${out//$'\n'/ }" >>"$log"
    # only notify on the first failure, not every run until you log back in.
    [[ "$prev" == *" FAIL "* ]] || notify "AWS SSO expired" "Run: aws login $profile"
    exit 1
  fi
  tail -n "$logLines" "$log" >"$log.tmp" && mv "$log.tmp" "$log"
}

case "${1:-}" in
on) cmd_on "${2:-}" ;;
off) cmd_off ;;
status) cmd_status ;;
run) cmd_run ;;
*) die "usage: aws-keepalive on [profile] | off | status | run" 2 ;;
esac
