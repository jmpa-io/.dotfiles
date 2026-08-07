#!/usr/bin/env zsh
# Tests for ~/.ai-aliases — shell function behaviour.
# Run with: zsh .config/common/bin/.tests/test-ai-aliases.sh

# Prefer ~/.dotfiles.d/ai-aliases (new layout), fall back to ~/.ai-aliases (legacy).
AI_ALIASES="${HOME}/.dotfiles.d/ai-aliases"
[[ -f "$AI_ALIASES" ]] || AI_ALIASES="${HOME}/.ai-aliases"

pass() { printf "\033[0;32mPASS\033[0m  %s\n" "$1"; }
fail() { printf "\033[0;31mFAIL\033[0m  %s\n" "$1"; FAILURES=$(( FAILURES + 1 )); }

FAILURES=0
TMPDIR_TEST=$(mktemp -d)
FAKE_BIN="$TMPDIR_TEST/bin"
EMPTY_ZDOTDIR="$TMPDIR_TEST/zdotdir"
mkdir -p "$FAKE_BIN" "$EMPTY_ZDOTDIR"

printf '#!/bin/sh\nif [ $# -eq 0 ]; then echo "FAKE_CLAUDE_CALLED:"; else echo "FAKE_CLAUDE_CALLED: $*"; fi\n' > "$FAKE_BIN/claude"
printf '#!/bin/sh\nif [ $# -eq 0 ]; then echo "FAKE_OPENCODE_CALLED:"; else echo "FAKE_OPENCODE_CALLED: $*"; fi\n' > "$FAKE_BIN/opencode"
chmod +x "$FAKE_BIN/claude" "$FAKE_BIN/opencode"

cleanup() { rm -rf "$TMPDIR_TEST"; }
trap cleanup EXIT

[[ -f "$AI_ALIASES" ]] || { echo "ERROR: $AI_ALIASES not found"; exit 1; }

# Helper: run a zsh -c snippet with:
#   - ZDOTDIR pointing to empty dir (no .zshenv — prevents Homebrew PATH prepend)
#   - FAKE_BIN first in PATH (fake claude/opencode take precedence over real ones)
#   - fzf stripped from PATH (prevents interactive picker)
_zsh() {
  local snippet="$1"
  local base_path
  # Strip fzf and homebrew-prepended paths; keep essentials.
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

# ── Test 2: all three functions are defined after sourcing ─────────────────────

for fn in claude opencode _worktree_pick; do
  result=$(ZDOTDIR="$EMPTY_ZDOTDIR" zsh -c "source $AI_ALIASES; type $fn" 2>&1)
  if echo "$result" | grep -q "shell function"; then
    pass "$fn is defined after sourcing"
  else
    fail "$fn is NOT defined after sourcing"
  fi
done

# ── Test 3: claude() with args forwards directly to command claude ─────────────

output=$(_zsh "claude --version")
if echo "$output" | grep -q "FAKE_CLAUDE_CALLED: --version"; then
  pass "claude() with args forwards directly to command claude"
else
  fail "claude() with args did NOT forward correctly (got: $output)"
fi

# ── Test 4: opencode() with args forwards directly to command opencode ─────────

output=$(_zsh "opencode run 'fix bug'")
if echo "$output" | grep -q "FAKE_OPENCODE_CALLED: run fix bug"; then
  pass "opencode() with args forwards directly to command opencode"
else
  fail "opencode() with args did NOT forward correctly (got: $output)"
fi

# ── Test 5: claude() without args runs command claude directly (no picker) ───────
# Covers both inside and outside a git repo — worktree selection is no longer
# claude()'s concern.

output=$(_zsh "cd $TMPDIR_TEST; claude")
if echo "$output" | grep -q "FAKE_CLAUDE_CALLED:$"; then
  pass "claude() without args runs command claude directly (no git repo)"
else
  fail "claude() without args outside git repo did NOT run directly (got: $output)"
fi

# ── Test 5b: claude() with no args inside a multi-worktree repo runs directly ───

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
  fail "claude() in multi-worktree repo did NOT run directly — picker may still be active (got: $output)"
fi

# ── Test 6: opencode() without args and no git repo just runs command opencode ─

output=$(_zsh "cd $TMPDIR_TEST; opencode")
if echo "$output" | grep -q "FAKE_OPENCODE_CALLED:$"; then
  pass "opencode() without args outside git repo runs command opencode directly"
else
  fail "opencode() without args outside git repo did NOT run directly (got: $output)"
fi

# ── Test 7: _worktree_pick returns nothing outside a git repo ──────────────────

output=$(_zsh "cd $TMPDIR_TEST; _worktree_pick 'test'")
if [[ -z "$output" ]]; then
  pass "_worktree_pick returns nothing outside a git repo"
else
  fail "_worktree_pick returned unexpected output outside git repo: $output"
fi

# ── Test 8: _worktree_pick returns nothing when only one worktree exists ────────

FAKE_REPO="$TMPDIR_TEST/repo"
mkdir -p "$FAKE_REPO"
git -C "$FAKE_REPO" init -q
GIT_AUTHOR_NAME="Test" GIT_AUTHOR_EMAIL="test@test.com" \
GIT_COMMITTER_NAME="Test" GIT_COMMITTER_EMAIL="test@test.com" \
git -C "$FAKE_REPO" commit --allow-empty -q -m "init"

output=$(_zsh "cd $FAKE_REPO; _worktree_pick 'test'")
if [[ -z "$output" ]]; then
  pass "_worktree_pick returns nothing when only one worktree exists"
else
  fail "_worktree_pick returned unexpected output with single worktree: $output"
fi

# ── Test 9: quarantine removal in claude() only runs when binary is newer ──────
# ver_file matches fake claude's "version" — binary is older — so xattr path is skipped.

VER_FILE="$TMPDIR_TEST/.claude/.last-xattr-version"
mkdir -p "$(dirname "$VER_FILE")"
# Write a version string; fake binary is timestamped older so no xattr run.
echo "99.9.9" > "$VER_FILE"
touch -t 197001010000 "$FAKE_BIN/claude"

output=$(ZDOTDIR="$EMPTY_ZDOTDIR" PATH="$FAKE_BIN:$(echo "$PATH" | tr ':' '\n' | grep -v fzf | tr '\n' ':' | sed 's/:$//')" HOME="$TMPDIR_TEST" zsh -c "source $AI_ALIASES; claude --version" 2>&1)

if echo "$output" | grep -q "FAKE_CLAUDE_CALLED"; then
  pass "claude() runs normally when binary is not newer than version file"
else
  fail "claude() failed to run when binary was not newer (got: $output)"
fi

# ── Results ───────────────────────────────────────────────────────────────────

echo
if [[ $FAILURES -eq 0 ]]; then
  printf "\033[0;32mAll tests passed.\033[0m\n"
else
  printf "\033[0;31m%d test(s) failed.\033[0m\n" "$FAILURES"
  exit 1
fi
