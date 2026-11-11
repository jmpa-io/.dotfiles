#!/usr/bin/env bash
# Tests aws-keepalive.sh using a stub 'aws' and a file-backed stub 'crontab'.
# Safe to run at any time — never touches your real crontab, AWS creds, or log.

set -uo pipefail

pass=0
fail=0
ok() {
  echo "  PASS  $1"
  pass=$((pass + 1))
}
nok() {
  echo "  FAIL  $1"
  fail=$((fail + 1))
}
check() { # check <label> <command...>
  local label="$1"
  shift
  if "$@"; then ok "$label"; else nok "$label"; fi
}

script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/aws-keepalive.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/stubs"

# stub aws: succeeds unless $tmp/aws-fail exists.
cat >"$tmp/stubs/aws" <<STUB
#!/usr/bin/env bash
if [[ -f "$tmp/aws-fail" ]]; then
  printf 'Error loading SSO Token\nToken has expired\n' >&2
  exit 255
fi
echo "arn:aws:sts::000000000000:assumed-role/test/me"
STUB

# stub crontab: backed by $tmp/crontab; 'crontab -l' fails like cron when empty.
cat >"$tmp/stubs/crontab" <<STUB
#!/usr/bin/env bash
f="$tmp/crontab"
case "\$1" in
  -l) [[ -s "\$f" ]] && cat "\$f" || { echo "no crontab for test" >&2; exit 1; } ;;
  -r) rm -f "\$f" ;;
  -) cat >"\$f" ;;
esac
STUB

# stub notify-send: records that it was called.
cat >"$tmp/stubs/notify-send" <<STUB
#!/usr/bin/env bash
echo "\$*" >>"$tmp/notified"
STUB
chmod +x "$tmp"/stubs/*

export PATH="$tmp/stubs:$PATH"
export AWS_KEEPALIVE_LOG="$tmp/keepalive.log"
export AWS_KEEPALIVE_PROFILE=testprofile
unset AWS_PROFILE
kp() { bash "$script" "$@"; }

echo "aws-keepalive"

# usage / validation.
kp bogus >/dev/null 2>&1
check "unknown command exits 2" test $? -eq 2
AWS_KEEPALIVE_PROFILE='' kp on >/dev/null 2>&1
check "on without a profile fails" test $? -ne 0
kp on 'bad profile;rm' >/dev/null 2>&1
check "on rejects unsafe profile name" test $? -ne 0
AWS_KEEPALIVE_INTERVAL=0 kp on x >/dev/null 2>&1
check "on rejects interval 0" test $? -ne 0
AWS_KEEPALIVE_INTERVAL=60 kp on x >/dev/null 2>&1
check "on rejects interval 60" test $? -ne 0
check "failed on left no crontab" test ! -e "$tmp/crontab"

# on / off, preserving unrelated entries and staying idempotent.
echo "0 3 * * * /usr/bin/backup" >"$tmp/crontab"
kp on testprofile >/dev/null
kp on testprofile >/dev/null
check "on adds exactly one entry" test "$(grep -c '# aws-keepalive' "$tmp/crontab")" -eq 1
check "on keeps unrelated entries" grep -q '/usr/bin/backup' "$tmp/crontab"
check "entry carries the profile" grep -q 'AWS_KEEPALIVE_PROFILE=testprofile' "$tmp/crontab"
check "entry runs every 15 min" grep -q '^\*/15 ' "$tmp/crontab"
check "status reports on" bash -c "bash '$script' status | head -n1 | grep -q '^on'"
kp off >/dev/null
check "off removes our entry" bash -c "! grep -q '# aws-keepalive' '$tmp/crontab'"
check "off keeps unrelated entries" grep -q '/usr/bin/backup' "$tmp/crontab"
check "status reports off" bash -c "bash '$script' status | head -n1 | grep -q '^off'"

# on / off with no crontab at all.
rm -f "$tmp/crontab"
kp on testprofile >/dev/null
check "on works with no existing crontab" grep -q '# aws-keepalive' "$tmp/crontab"
kp off >/dev/null
check "off with only our entry empties the crontab" test ! -s "$tmp/crontab"
kp off >/dev/null
check "off is idempotent" test $? -eq 0

# run: success logs ok, failure logs FAIL on one line and notifies once.
kp run
check "run succeeds when aws succeeds" test $? -eq 0
check "run logs ok" grep -q ' ok arn:' "$tmp/keepalive.log"
touch "$tmp/aws-fail"
kp run
check "run fails when aws fails" test $? -eq 1
check "run logs FAIL on a single line" test "$(grep -c ' FAIL .*Token has expired' "$tmp/keepalive.log")" -eq 1
check "first failure notifies" test "$(wc -l <"$tmp/notified" 2>/dev/null | tr -d ' ')" -eq 1
kp run
check "repeat failure does not re-notify" test "$(wc -l <"$tmp/notified" | tr -d ' ')" -eq 1
check "notification names the sso login command" grep -q 'aws sso login --profile testprofile' "$tmp/notified"
check "status says FAILING with a count" bash -c "bash '$script' status | grep -q 'FAILING since .* (2 consecutive FAIL); last ok '"
echo 1999-01-01 >"$tmp/keepalive.log.notified"
kp run
check "repeat failure re-notifies on a new day" test "$(wc -l <"$tmp/notified" | tr -d ' ')" -eq 2
kp run
check "and only once that day" test "$(wc -l <"$tmp/notified" | tr -d ' ')" -eq 2
rm "$tmp/aws-fail"
kp run
check "status says healthy after recovery" bash -c "bash '$script' status | grep -q '^healthy: last ok '"
check "recovers after failure" bash -c "tail -n1 '$tmp/keepalive.log' | grep -q ' ok '"

# the log is trimmed even while failing.
touch "$tmp/aws-fail"
for _ in $(seq 1 250); do echo "x FAIL y" >>"$tmp/keepalive.log"; done
kp run
check "log is trimmed to 200 lines while failing" test "$(wc -l <"$tmp/keepalive.log" | tr -d ' ')" -eq 200
rm "$tmp/aws-fail"

# log is trimmed.
for _ in $(seq 1 250); do echo "x ok" >>"$tmp/keepalive.log"; done
kp run
check "log is trimmed to 200 lines" test "$(wc -l <"$tmp/keepalive.log" | tr -d ' ')" -eq 200

# expiry warning (needs jq; uses a fake HOME with a fake SSO cache).
if hash jq 2>/dev/null; then
  fakeHome="$tmp/home"
  mkdir -p "$fakeHome/.aws/sso/cache"
  future() { date -u -d "+$1 days" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v+"$1"d +%Y-%m-%dT%H:%M:%SZ; }
  cache() { printf '{"refreshToken":"x","registrationExpiresAt":"%s"}\n' "$(future "$1")" >"$fakeHome/.aws/sso/cache/a.json"; }
  : >"$tmp/keepalive.log"
  rm -f "$tmp/notified" "$tmp/keepalive.log.warned"

  cache 60
  HOME="$fakeHome" kp run
  check "no warning when expiry is far off" test ! -e "$tmp/notified"
  check "status shows the expiry date" bash -c "HOME='$fakeHome' bash '$script' status | grep -q 'sso registration expires: 20'"

  cache 3
  HOME="$fakeHome" kp run
  check "warns when expiry is close" grep -q 'login needed soon' "$tmp/notified"
  check "warning is logged" grep -q ' warn sso registration expires in' "$tmp/keepalive.log"
  HOME="$fakeHome" kp run
  check "warns only once a day" test "$(wc -l <"$tmp/notified" | tr -d ' ')" -eq 1
  echo 1999-01-01 >"$tmp/keepalive.log.warned"
  HOME="$fakeHome" kp run
  check "warns again on a new day" test "$(wc -l <"$tmp/notified" | tr -d ' ')" -eq 2
else
  echo "  SKIP  expiry warning tests (jq not installed)"
fi

echo
echo "  $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
