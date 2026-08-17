#!/usr/bin/env bash
# Start claude in a tmux pane if not running, then send a prompt file to it.
# Autodiscovers the next free pane in work-* sessions if no pane is specified.
# Usage:
#   claude-dispatch <prompt-file>              — autodiscover next free work-* pane
#   claude-dispatch <pane> <prompt-file>       — target a specific pane

set -euo pipefail

die() { echo "claude-dispatch: $1" >&2; exit 1; }

# Autodiscover the next work-* pane not running claude.
_next_free_pane() {
  tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} #{pane_pid}' \
    | awk '/^work-/' \
    | while read -r pane pane_pid; do
        pgrep -P "$pane_pid" -x claude &>/dev/null || { echo "$pane"; break; }
      done
}

# Resolve args — support both 1-arg (autodiscover) and 2-arg (explicit pane) forms.
if [[ $# -eq 1 ]]; then
  prompt_file="$1"
  pane=$(_next_free_pane)
  [[ -z "$pane" ]] && die "no free work-* pane found (all running claude)"
  echo "claude-dispatch: autodiscovered pane $pane"
elif [[ $# -eq 2 ]]; then
  pane="$1"
  prompt_file="$2"
else
  die "usage: claude-dispatch [pane] <prompt-file>"
fi

[[ -f "$prompt_file" ]] || die "file not found: $prompt_file"

# Verify pane exists.
pane_pid=$(tmux display-message -p -t "$pane" '#{pane_pid}' 2>/dev/null) \
  || die "pane not found: $pane"
[[ -z "$pane_pid" ]] && die "pane not found: $pane"

# Start claude if not already running.
if ! pgrep -P "$pane_pid" -x claude &>/dev/null; then
  tmux send-keys -t "$pane" 'claude' Enter

  # Wait for claude child process to appear (up to 10s).
  i=0
  while (( i++ < 100 )); do
    pgrep -P "$pane_pid" -x claude &>/dev/null && break
    sleep 0.1
  done
  pgrep -P "$pane_pid" -x claude &>/dev/null || die "claude did not start in pane $pane"

  # Handle trust prompt if it appears.
  j=0
  while (( j++ < 50 )); do
    output=$(tmux capture-pane -t "$pane" -p 2>/dev/null)
    if printf '%s' "$output" | grep -q "Yes, I trust this folder"; then
      tmux send-keys -t "$pane" '1' Enter
      break
    fi
    sleep 0.1
  done

  # Wait for the claude prompt (❯) — up to 15s.
  k=0
  while (( k++ < 150 )); do
    ready=$(tmux capture-pane -t "$pane" -p 2>/dev/null)
    printf '%s' "$ready" | grep -q '❯' && break
    sleep 0.1
  done

fi

# Send the prompt.
tmux send-keys -l -t "$pane" "$(cat "$prompt_file")"

# Handle claude's paste-expand confirmation — poll and send again to confirm.
p=0
while (( p++ < 50 )); do
  output=$(tmux capture-pane -t "$pane" -p 2>/dev/null)
  if printf '%s' "$output" | grep -q "paste again to expand"; then
    tmux send-keys -l -t "$pane" "$(cat "$prompt_file")"
    break
  fi
  sleep 0.1
done

tmux send-keys -t "$pane" Enter
echo "claude-dispatch: sent $(basename "$prompt_file") -> $pane"
