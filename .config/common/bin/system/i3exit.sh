#!/usr/bin/env bash
# This script handles session and power actions for i3 (logout, suspend, etc.).
# It replaces Manjaro's 'i3exit' (and its 'blurlock'), so the same i3 config
# works on both Manjaro and Arch Linux.
#
# Usage: i3exit.sh lock|logout|switch_user|suspend|hibernate|reboot|shutdown
# Set I3EXIT_DRY_RUN=1 to print the command instead of running it.

dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
lock="$dir/lock.sh"

# use systemctl under systemd, otherwise loginctl.
[[ "$(cat /proc/1/comm)" == "systemd" ]] && logind=systemctl || logind=loginctl

run() {
  if [[ -n "$I3EXIT_DRY_RUN" ]]; then
    echo "would run: $*"
  else
    "$@"
  fi
}

case "$1" in
  lock)         run "$lock" ;;
  logout)       run i3-msg exit ;;
  switch_user)  run dm-tool switch-to-greeter ;;
  suspend)      run "$lock" && run "$logind" suspend ;;
  hibernate)    run "$lock" && run "$logind" hibernate ;;
  reboot)       run "$logind" reboot ;;
  shutdown)     run "$logind" poweroff ;;
  *)
    echo "i3exit: missing or invalid argument" >&2
    echo "Try again with: lock | logout | switch_user | suspend | hibernate | reboot | shutdown" >&2
    exit 2
    ;;
esac
