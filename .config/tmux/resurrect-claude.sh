#!/usr/bin/env bash
# tmux session manager: debug, save, and restore claude panes.
# Usage: resurrect-claude.sh [status|save|restore|hook]

SAVE_DIR="$HOME/.local/share/tmux/resurrect"
SAVE_FILE="$SAVE_DIR/last"
AI_PROCS=("claude")

cmd="${1:-status}"

if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; BLUE=''; BOLD=''; NC=''
fi

is_ai_proc() {
  local c="$1"
  for p in "${AI_PROCS[@]}"; do
    [[ "$c" == "$p" ]] && return 0
  done
  return 1
}

pane_live_cmd() {
  tmux display-message -p -t "$1" '#{pane_current_command}' 2>/dev/null || echo "?"
}

# Parse the save file, yield AI pane lines: session window pane dir full_cmd
parse_save() {
  [[ -f "$SAVE_FILE" ]] || return 0
  while IFS=$'\t' read -r type session window _ _ pane _ dir _ _ full_cmd; do
    [[ "$type" == "pane" ]] || continue
    full_cmd="${full_cmd#:}"
    dir="${dir#:}"
    is_ai_proc "$full_cmd" || continue
    echo "$session $window $pane $dir $full_cmd"
  done < "$SAVE_FILE"
}

restore_cmd_for() {
  local proc="$1"
  case "$proc" in
    claude)   echo "claude --continue" ;;
    *)        echo "$proc" ;;
  esac
}

cmd_status() {
  echo -e "${BOLD}${BLUE}Live AI panes${NC}"
  local any_live=0
  while IFS= read -r line; do
    read -r target live_cmd dir <<< "$line"
    printf "  ${GREEN}✓${NC}  %-22s  ${YELLOW}%-10s${NC}  %s\n" "$target" "$live_cmd" "$dir"
    any_live=1
  done < <(
    tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} #{pane_current_command} #{pane_current_path}' 2>/dev/null \
      | while read -r target c dir; do is_ai_proc "$c" && echo "$target $c $dir"; done
  )
  [[ $any_live -eq 0 ]] && echo "  (none running)"

  echo
  echo -e "${BOLD}${BLUE}Last resurrect save${NC}  ($(stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$SAVE_FILE" 2>/dev/null || echo 'unknown'))"
  [[ -f "$SAVE_FILE" ]] || { echo "  (no save file at $SAVE_FILE)"; return; }

  local any_saved=0
  while read -r session window pane dir full_cmd; do
    local target="${session}:${window}.${pane}"
    local live
    live=$(pane_live_cmd "$target")
    local icon
    if is_ai_proc "$live"; then
      icon="${GREEN}✓ running ${NC}"
    elif [[ "$live" == "zsh" || "$live" == "bash" ]]; then
      icon="${YELLOW}⚠ stopped  ${NC}"
    else
      icon="${RED}✗ gone     ${NC}"
    fi
    printf "  [%b]  %-22s  saved=${YELLOW}%-10s${NC}  live=${YELLOW}%-10s${NC}  %s\n" \
      "$icon" "$target" "$full_cmd" "$live" "$dir"
    any_saved=1
  done < <(parse_save)
  [[ $any_saved -eq 0 ]] && echo "  (no AI panes in last save)"

  echo
  echo -e "${BOLD}Commands:${NC}  ${YELLOW}s${NC}ave  ${YELLOW}r${NC}estore  ${YELLOW}q${NC}uit"
  read -rsn1 key
  case "$key" in
    s) cmd_save ;;
    r) cmd_relaunch ;;
    q|$'\e') exit 0 ;;
  esac
}

cmd_save() {
  echo -e "${BLUE}Saving tmux state...${NC}"
  tmux run-shell "~/.config/tmux/plugins/tmux-resurrect/scripts/save.sh" 2>/dev/null
  sleep 1
  echo -e "${GREEN}Done.${NC} $(ls -t "$SAVE_DIR"/tmux_resurrect_*.txt 2>/dev/null | head -1)"
}

cmd_relaunch() {
  [[ -f "$SAVE_FILE" ]] || { echo -e "${RED}No save file.${NC}"; return 1; }
  local count=0
  while read -r session window pane dir full_cmd; do
    local target="${session}:${window}.${pane}"
    local live
    live=$(pane_live_cmd "$target")
    if ! is_ai_proc "$live"; then
      local rc
      rc=$(restore_cmd_for "$full_cmd")
      echo -e "  ${YELLOW}→${NC} $target  launching: $rc  (was: $live, dir: $dir)"
      tmux send-keys -t "$target" "$rc" Enter 2>/dev/null
      (( count++ )) || true
    else
      echo -e "  ${GREEN}✓${NC} $target  already running: $live"
    fi
  done < <(parse_save)
  echo -e "${GREEN}Done.${NC} Relaunched $count pane(s)."
}

# Called by @resurrect-hook-post-restore-all (disabled by default — inline strategy handles it).
# Re-enable in tmux.conf if you need hook-based restoration.
cmd_hook() {
  [[ -f "$SAVE_FILE" ]] || exit 0
  sleep 2
  while read -r session window pane dir full_cmd; do
    local rc
    rc=$(restore_cmd_for "$full_cmd")
    sleep 0.3
    tmux send-keys -t "${session}:${window}.${pane}" "$rc" Enter 2>/dev/null
  done < <(parse_save)
}

case "$cmd" in
  status)  cmd_status ;;
  save)    cmd_save ;;
  restore) cmd_relaunch ;;
  hook)    cmd_hook ;;
  *)
    echo "Usage: $(basename "$0") [status|save|restore|hook]"
    echo "  status   show live AI panes + last save state (default, interactive)"
    echo "  save     trigger a resurrect save now"
    echo "  restore  re-launch AI in any stopped panes from last save"
    echo "  hook     internal — called by resurrect post-restore hook"
    exit 1
    ;;
esac
