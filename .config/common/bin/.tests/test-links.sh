#!/usr/bin/env bash
# Tests for the Makefile's link-backup / cfg-home macros: a real file in $HOME must be
# backed up (never lost), links must be idempotent, and nothing may be written into the repo.
# Run with: bash .config/common/bin/.tests/test-links.sh (from anywhere; uses a temp HOME)
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
failures=0
pass() { printf "\033[0;32mPASS\033[0m  %s\n" "$1"; }
fail() {
  printf "\033[0;31mFAIL\033[0m  %s\n" "$1"
  failures=$((failures + 1))
}
run() { (cd "$repo" && HOME="$tmp" PWD="$repo" make --no-print-directory "$@" >/dev/null 2>&1); }

# 1. a differing real file is backed up, then replaced by a link.
echo "my local ssh config" >"$tmp/.zshenv"
run configure-zsh
backups=("$tmp"/.zshenv.dotfiles-bak.*)
if [[ -L "$tmp/.zshenv" && -f "${backups[0]}" && "$(cat "${backups[0]}")" == "my local ssh config" ]]; then
  pass "differing real file is backed up and replaced by a link"
else
  fail "differing real file was not backed up correctly"
fi

# 2. re-running creates no further backups.
run configure-zsh
backups=("$tmp"/.zshenv.dotfiles-bak.*)
if [[ ${#backups[@]} -eq 1 ]]; then
  pass "re-run is idempotent (no extra backups)"
else
  fail "re-run created extra backups: ${backups[*]}"
fi

# 3. an identical real file is just relinked, without a backup.
rm -f "$tmp/.zshenv" "$tmp"/.zshenv.dotfiles-bak.*
cp "$repo/.config/zsh/.zshenv" "$tmp/.zshenv"
run configure-zsh
if [[ -L "$tmp/.zshenv" ]] && ! compgen -G "$tmp/.zshenv.dotfiles-bak.*" >/dev/null; then
  pass "identical real file is relinked without a backup"
else
  fail "identical real file was backed up or not relinked"
fi

[[ $failures -eq 0 ]] || {
  printf "\033[0;31m%d test(s) failed.\033[0m\n" "$failures"
  exit 1
}
printf "\033[0;32mAll tests passed.\033[0m\n"
