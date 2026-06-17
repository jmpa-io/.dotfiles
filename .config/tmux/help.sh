#!/usr/bin/env bash
# tmux help — displayed via fzf for clean rendering
# Dracula theme colors passed directly to fzf

export FZF_DEFAULT_OPTS=""

entries=(
  "SPLITS──────────────────────────────────────────────────────"
  "Ctrl+\\                │  Split pane to the RIGHT"
  "Ctrl+G                │  Split pane DOWNWARD"
  " "
  "PANES───────────────────────────────────────────────────────"
  "Alt + Arrow           │  Move focus between panes"
  "mouse click           │  Click any pane to focus it"
  "Ctrl+B z              │  Zoom pane fullscreen (toggle)"
  " "
  "WINDOWS─────────────────────────────────────────────────────"
  "Shift + Left          │  Previous window"
  "Shift + Right         │  Next window"
  "Ctrl+B c              │  New window (opens in current path)"
  " "
  "SESSIONS────────────────────────────────────────────────────"
  "s-work                │  2x2 grid — CBA work session"
  "s-homelab             │  3 panes — homelab (main left, 2 right)"
  "s-misc                │  Single pane — misc shell"
  "Ctrl+B d              │  Detach (session keeps running)"
  " "
  "CONFIG──────────────────────────────────────────────────────"
  "Ctrl+B r              │  Reload tmux config"
  "Ctrl+B ?              │  Show this help"
  " "
  "BROADCAST───────────────────────────────────────────────────"
  "b-src                 │  source ~/work in every pane"
)

printf '%s\n' "${entries[@]}" | fzf \
  --no-sort \
  --no-mouse \
  --height=100% \
  --layout=reverse \
  --border=rounded \
  --border-label=" 🧛 tmux cheatsheet  •  prefix = Ctrl+B " \
  --border-label-pos=top \
  --prompt="" \
  --pointer="" \
  --header="  type to search  •  Esc to close" \
  --header-first \
  --color="bg:#282a36,bg+:#44475a,fg:#f8f8f2,fg+:#f8f8f2" \
  --color="border:#bd93f9,label:#bd93f9,header:#6272a4" \
  --color="hl:#50fa7b,hl+:#50fa7b,prompt:#bd93f9" \
  --color="pointer:#ff79c6,marker:#ff79c6,spinner:#ffb86c" \
  --no-info \
  2>/dev/null

exit 0
