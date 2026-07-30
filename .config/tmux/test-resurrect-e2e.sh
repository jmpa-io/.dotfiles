#!/usr/bin/env bash
# End-to-end proof that the tmux resurrect + claude --continue flow works.
#
# What this proves:
#   1. A claude session started in a directory can be saved by resurrect
#   2. After the pane is killed, resurrect-claude.sh restore sends "claude --continue"
#   3. "claude --continue" in that directory actually resumes the right session
#      (verified by asking claude to recall something it was told in step 1)
#
# Prerequisites: claude CLI, tmux running, resurrect save dir exists.

set -euo pipefail

SCRIPT="$(dirname "$0")/resurrect-claude.sh"
SAVE_FILE="$HOME/.local/share/tmux/resurrect/last"
BACKUP="$SAVE_FILE.e2e-backup"
SESSION="e2e-resurrect-$$"
WORKDIR="/tmp/e2e-resurrect-$$"
MARKER="PLUTO_$(date +%s)"  # unique word claude will be asked to remember
RESULT_FILE="/tmp/e2e-result-$$.txt"

pass() { printf "\033[0;32mPASS\033[0m  %s\n" "$1"; }
fail() { printf "\033[0;31mFAIL\033[0m  %s\n" "$1"; FAILURES=$(( FAILURES + 1 )); }
info() { printf "\033[0;34m    …\033[0m  %s\n" "$1"; }

FAILURES=0
cleanup() {
  tmux kill-session -t "$SESSION" 2>/dev/null || true
  [[ -f "$BACKUP" ]] && mv "$BACKUP" "$SAVE_FILE" || true
  rm -rf "$WORKDIR" "$RESULT_FILE"
}
trap cleanup EXIT

# ── Preflight ─────────────────────────────────────────────────────────────────

[[ -x "$SCRIPT" ]]      || { echo "ERROR: $SCRIPT not found"; exit 1; }
[[ -f "$SAVE_FILE" ]]   || { echo "ERROR: no resurrect save file at $SAVE_FILE — run a tmux save first"; exit 1; }
command -v claude >/dev/null || { echo "ERROR: claude not in PATH"; exit 1; }
[[ -n "${TMUX:-}" ]]    || { echo "ERROR: not inside a tmux session — run this from inside tmux"; exit 1; }

mkdir -p "$WORKDIR"
cp "$SAVE_FILE" "$BACKUP"

echo
echo "Marker word: $MARKER"
echo "Working dir: $WORKDIR"
echo

# ── Step 1: Start claude in a new tmux window, plant the marker ───────────────

info "Creating test window and starting claude..."
tmux new-window -t "$SESSION" -c "$WORKDIR" 2>/dev/null || {
  tmux new-session -d -s "$SESSION" -c "$WORKDIR" -x 180 -y 50
}
WIN=$(tmux display-message -p -t "$SESSION" '#{window_index}')
PANE="${SESSION}:${WIN}.1"

# Start claude non-interactively: tell it to remember the marker word
info "Asking claude to remember $MARKER ..."
tmux send-keys -t "$PANE" \
  "command claude -p 'Remember the word $MARKER. Reply with only: remembered'" \
  Enter

# Wait for claude to respond (up to 30s)
for i in $(seq 1 30); do
  sleep 1
  output=$(tmux capture-pane -t "$PANE" -p)
  if echo "$output" | grep -qi "remembered"; then
    break
  fi
  [[ $i -eq 30 ]] && { fail "claude did not respond in 30s"; exit 1; }
done
pass "claude responded in step 1"

# ── Step 2: Inject a save entry for this pane, kill the pane ─────────────────

info "Injecting save entry and killing pane..."
cat > "$SAVE_FILE" <<EOF
pane	${SESSION}	${WIN}	1	:*	1	test	:${WORKDIR}	1	zsh	:claude
EOF

tmux send-keys -t "$PANE" "" ""  # make sure shell is ready
sleep 0.3

# Kill claude process if still running, leave pane at shell
tmux send-keys -t "$PANE" "q" "" 2>/dev/null || true
sleep 0.3
tmux send-keys -t "$PANE" "" Enter  # back to shell prompt

sleep 0.5
live=$(tmux display-message -p -t "$PANE" '#{pane_current_command}')
info "Pane command after kill: $live"

# ── Step 3: Run restore, verify "claude --continue" is sent ───────────────────

info "Running resurrect-claude.sh restore..."
restore_output=$(bash "$SCRIPT" restore 2>&1)
info "Restore output: $restore_output"

sleep 0.5
pane_contents=$(tmux capture-pane -t "$PANE" -p)
if echo "$pane_contents" | grep -q "claude --continue"; then
  pass "restore sent 'claude --continue' to the pane"
else
  fail "restore did NOT send 'claude --continue'"
  echo "     pane: $(echo "$pane_contents" | tail -5)"
fi

# ── Step 4: Let claude --continue start, ask it to recall the marker ──────────

info "Waiting for claude --continue to start..."
for i in $(seq 1 30); do
  sleep 1
  live=$(tmux display-message -p -t "$PANE" '#{pane_current_command}' 2>/dev/null || echo "?")
  if [[ "$live" == "claude" ]]; then
    break
  fi
  [[ $i -eq 30 ]] && { fail "claude --continue did not start within 30s"; exit 1; }
done
pass "claude --continue is running"

info "Asking claude to recall the marker word..."
tmux send-keys -t "$PANE" "What word did I ask you to remember? Reply with only the word." Enter

for i in $(seq 1 45); do
  sleep 1
  output=$(tmux capture-pane -t "$PANE" -p)
  if echo "$output" | grep -qi "$MARKER"; then
    pass "claude recalled '$MARKER' — session continuity confirmed"
    break
  fi
  if [[ $i -eq 45 ]]; then
    fail "claude did NOT recall '$MARKER' after 45s"
    echo "     last pane output:"
    echo "$output" | tail -10 | sed 's/^/       /'
  fi
done

# ── Results ───────────────────────────────────────────────────────────────────

echo
if [[ $FAILURES -eq 0 ]]; then
  printf "\033[0;32mAll checks passed — tmux resurrect + claude --continue is working end-to-end.\033[0m\n"
else
  printf "\033[0;31m%d check(s) failed.\033[0m\n" "$FAILURES"
  exit 1
fi
