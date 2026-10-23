#!/usr/bin/env zsh
# Tests for ~/.ai-aliases — shell function behaviour.
# Run with: zsh .config/common/bin/.tests/test-ai-aliases.sh

# Prefer ~/.dotfiles.d/ai-aliases (new layout), fall back to ~/.ai-aliases (legacy).
AI_ALIASES="${HOME}/.dotfiles.d/ai-aliases"
[[ -f "$AI_ALIASES" ]] || AI_ALIASES="${HOME}/.ai-aliases"

pass() { printf "\033[0;32mPASS\033[0m  %s\n" "$1"; }
fail() {
  printf "\033[0;31mFAIL\033[0m  %s\n" "$1"
  FAILURES=$((FAILURES + 1))
}

FAILURES=0
TMPDIR_TEST=$(mktemp -d)
FAKE_BIN="$TMPDIR_TEST/bin"
EMPTY_ZDOTDIR="$TMPDIR_TEST/zdotdir"
mkdir -p "$FAKE_BIN" "$EMPTY_ZDOTDIR"

printf '#!/bin/sh\nif [ $# -eq 0 ]; then echo "FAKE_CLAUDE_CALLED:"; else echo "FAKE_CLAUDE_CALLED: $*"; fi\n' >"$FAKE_BIN/claude"
chmod +x "$FAKE_BIN/claude"

cleanup() { rm -rf "$TMPDIR_TEST"; }
trap cleanup EXIT

[[ -f "$AI_ALIASES" ]] || {
  echo "ERROR: $AI_ALIASES not found"
  exit 1
}

# Helper: run a zsh -c snippet with:
#   - ZDOTDIR pointing to empty dir (no .zshenv — prevents Homebrew PATH prepend)
#   - FAKE_BIN first in PATH (fake claude takes precedence over real one)
#   - fzf stripped from PATH (no interactive pickers)
_zsh() {
  local snippet="$1"
  local base_path
  base_path=$(echo "$PATH" | tr ':' '\n' | grep -v fzf | tr '\n' ':' | sed 's/:$//')
  ZDOTDIR="$EMPTY_ZDOTDIR" PATH="$FAKE_BIN:$base_path" zsh -c "source $AI_ALIASES; $snippet" 2>&1
}

# ── Test 1: file sources without errors ───────────────────────────────────────

source_output=$(ZDOTDIR="$EMPTY_ZDOTDIR" zsh -c "source $AI_ALIASES" 2>&1)
if [[ $? -eq 0 && -z "$source_output" ]]; then
  pass "sources without errors or output"
else
  fail "source produced errors: $source_output"
fi

# ── Test 2: claude() is defined after sourcing ────────────────────────────────

result=$(ZDOTDIR="$EMPTY_ZDOTDIR" zsh -c "source $AI_ALIASES; type claude" 2>&1)
if echo "$result" | grep -q "shell function"; then
  pass "claude is defined after sourcing"
else
  fail "claude is NOT defined after sourcing"
fi

# ── Test 3: claude() with args forwards directly to command claude ─────────────

output=$(_zsh "claude --version")
if echo "$output" | grep -q "FAKE_CLAUDE_CALLED: --version"; then
  pass "claude() with args forwards directly to command claude"
else
  fail "claude() with args did NOT forward correctly (got: $output)"
fi

# ── Test 4: claude() without args runs command claude directly ────────────────

output=$(_zsh "cd $TMPDIR_TEST; claude")
if echo "$output" | grep -q "FAKE_CLAUDE_CALLED:$"; then
  pass "claude() without args runs command claude directly"
else
  fail "claude() without args did NOT run directly (got: $output)"
fi

# ── Test 5: claude() with no args inside a multi-worktree repo runs directly ──

MULTI_REPO="$TMPDIR_TEST/multi-repo"
mkdir -p "$MULTI_REPO"
git -C "$MULTI_REPO" init -q
GIT_AUTHOR_NAME="Test" GIT_AUTHOR_EMAIL="test@test.com" \
  GIT_COMMITTER_NAME="Test" GIT_COMMITTER_EMAIL="test@test.com" \
  git -C "$MULTI_REPO" commit --allow-empty -q -m "init"
git -C "$MULTI_REPO" worktree add -q "$MULTI_REPO/.worktrees/feat-x" -b feat-x 2>/dev/null

output=$(_zsh "cd $MULTI_REPO; claude")
if echo "$output" | grep -q "FAKE_CLAUDE_CALLED:$"; then
  pass "claude() with no args in multi-worktree repo runs command claude directly"
else
  fail "claude() in multi-worktree repo did NOT run directly (got: $output)"
fi

# ── Test 6: quarantine is stripped when the attribute is present ──────────────
# fake xattr reports the attribute present on -p, and succeeds on -d — claude
# should still run normally afterwards.

FAKE_XATTR="$FAKE_BIN/xattr"
printf '#!/bin/sh\ncase "$1" in\n  -p) exit 0 ;;\n  -d) exit 0 ;;\nesac\n' >"$FAKE_XATTR"
chmod +x "$FAKE_XATTR"

output=$(_zsh "claude --version")
if echo "$output" | grep -q "FAKE_CLAUDE_CALLED: --version"; then
  pass "claude() strips quarantine when present and still runs normally"
else
  fail "claude() did not run after stripping quarantine (got: $output)"
fi

# ── Test 7: no xattr -d call when the attribute is absent ────────────────────
# fake xattr reports the attribute absent on -p, and fails hard if -d is ever
# called — proves claude() skips the strip entirely when there's nothing to do.

printf '#!/bin/sh\ncase "$1" in\n  -p) exit 1 ;;\n  -d) echo "UNEXPECTED_XATTR_D_CALL" >&2; exit 1 ;;\nesac\n' >"$FAKE_XATTR"
chmod +x "$FAKE_XATTR"

output=$(_zsh "claude --version")
if echo "$output" | grep -q "UNEXPECTED_XATTR_D_CALL"; then
  fail "claude() called xattr -d even though the attribute was absent"
else
  pass "claude() does not call xattr -d when the attribute is absent"
fi

# ── Test 8: failed xattr -d warns but still runs claude ──────────────────────
# fake xattr reports the attribute present both before and after -d (simulating
# a permission failure) — claude() must print the sudo remediation hint to
# stderr and still invoke the real binary rather than blocking.

printf '#!/bin/sh\ncase "$1" in\n  -p) exit 0 ;;\n  -d) exit 1 ;;\nesac\n' >"$FAKE_XATTR"
chmod +x "$FAKE_XATTR"

output=$(_zsh "claude --version")
if echo "$output" | grep -q "failed to clear quarantine" && echo "$output" | grep -q "FAKE_CLAUDE_CALLED: --version"; then
  pass "claude() warns and still runs when xattr -d fails"
else
  fail "claude() did not warn and run correctly on xattr -d failure (got: $output)"
fi

# ── Results ───────────────────────────────────────────────────────────────────

echo
if [[ $FAILURES -eq 0 ]]; then
  printf "\033[0;32mAll tests passed.\033[0m\n"
else
  printf "\033[0;31m%d test(s) failed.\033[0m\n" "$FAILURES"
  exit 1
fi
