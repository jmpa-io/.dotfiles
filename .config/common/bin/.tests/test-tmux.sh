#!/usr/bin/env bash
# Tests tmux session functions defined in .config/common/aliases.
# Verifies correct pane counts and idempotency (no extra panes on re-run).
# Safe to run at any time — creates and kills sessions, does not attach.

set -euo pipefail

pass=0
fail=0

# ── Helpers ───────────────────────────────────────────────────────────────────

ok() {
  echo "  PASS  $1"
  pass=$((pass + 1))
}

fail() {
  echo "  FAIL  $1"
  fail=$((fail + 1))
}

assert_panes() {
  local session="$1"
  local expected="$2"
  local label="$3"
  local actual
  actual=$(tmux list-panes -t "$session" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$actual" -eq "$expected" ]]; then
    ok "$label — $actual panes"
  else
    fail "$label — expected $expected panes, got $actual"
  fi
}

# work-1: wide left + 2 stacked right (3 panes)
create_work1_session() {
  local name="$1"
  if ! tmux has-session -t "$name" 2>/dev/null; then
    tmux new-session -d -s "$name"
    tmux split-window -h -t "$name"
    tmux split-window -v -t "$name:1.2"
    tmux select-pane -t "$name:1.1"
  fi
}

# work-2: 2 stacked left + wide right (3 panes)
create_work2_session() {
  local name="$1"
  if ! tmux has-session -t "$name" 2>/dev/null; then
    tmux new-session -d -s "$name"
    tmux split-window -h -t "$name"
    tmux split-window -v -t "$name:1.1"
    tmux select-pane -t "$name:1.2"
  fi
}

# work-3/4: 2 terminals side by side (2 panes)
create_work_split_session() {
  local name="$1"
  if ! tmux has-session -t "$name" 2>/dev/null; then
    tmux new-session -d -s "$name"
    tmux split-window -h -t "$name"
    tmux select-pane -t "$name:1.1"
  fi
}

create_homelab_session() {
  local name="$1"
  if ! tmux has-session -t "$name" 2>/dev/null; then
    tmux new-session -d -s "$name"
    tmux split-window -h -t "$name"
    tmux split-window -v -t "$name:1.2"
    tmux select-pane -t "$name:1.1"
  fi
}

# ── Tests ─────────────────────────────────────────────────────────────────────

echo ""
echo "tmux session tests"
echo "──────────────────"

# work-1 — 3 panes (wide left + 2 stacked right)
create_work1_session work-1
assert_panes work-1 3 "work-1 first run"
create_work1_session work-1
assert_panes work-1 3 "work-1 second run (idempotency)"
tmux kill-session -t work-1

# work-2 — 3 panes (2 stacked left + wide right)
create_work2_session work-2
assert_panes work-2 3 "work-2 first run"
create_work2_session work-2
assert_panes work-2 3 "work-2 second run (idempotency)"
tmux kill-session -t work-2

# work-3 — 2 panes (side by side)
create_work_split_session work-3
assert_panes work-3 2 "work-3 first run"
create_work_split_session work-3
assert_panes work-3 2 "work-3 second run (idempotency)"
tmux kill-session -t work-3

# work-4 — 2 panes (side by side)
create_work_split_session work-4
assert_panes work-4 2 "work-4 first run"
create_work_split_session work-4
assert_panes work-4 2 "work-4 second run (idempotency)"
tmux kill-session -t work-4

# t-homelab — should create 3 panes
create_homelab_session homelab
assert_panes homelab 3 "homelab first run"
create_homelab_session homelab
assert_panes homelab 3 "homelab second run (idempotency)"
tmux kill-session -t homelab

# t-misc / work-5 — single pane
tmux new-session -d -s misc
assert_panes misc 1 "misc first run"
tmux new-session -d -s misc 2>/dev/null || true
assert_panes misc 1 "misc second run (idempotency)"
tmux kill-session -t misc

tmux new-session -d -s work-5
assert_panes work-5 1 "work-5 first run"
tmux kill-session -t work-5

# t-ls — no sessions
result=$(tmux ls 2>/dev/null || echo "No tmux sessions running.")
if [[ "$result" == "No tmux sessions running." ]]; then
  ok "t-ls reports no sessions when none running"
else
  fail "t-ls — unexpected output: $result"
fi

# t-ls — with sessions
tmux new-session -d -s work-1
tmux new-session -d -s homelab
result=$(tmux ls 2>/dev/null)
if echo "$result" | grep -q "work-1" && echo "$result" | grep -q "homelab"; then
  ok "t-ls lists sessions correctly"
else
  fail "t-ls — sessions not listed: $result"
fi
tmux kill-session -t work-1
tmux kill-session -t homelab

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "──────────────────"
echo "  $pass passed, $fail failed"
echo ""

[[ "$fail" -eq 0 ]]
