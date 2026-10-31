#!/usr/bin/env bash
# Interactive devbox check. Run inside the devbox (VNC desktop up) as the tester
# user: drives i3 keybinds, rofi, the Print key, polybar, the lock screen, dunst,
# nvim and the make test targets via xdotool, saving screenshots to $OUT.
# Each check prints PASS/FAIL; the exit code is the number of failed checks.
# Usage: DEVBOX_PASSWORD=... test/arch/devbox-check.sh   (run from the repo root)
# shellcheck disable=SC2016,SC2015
export DISPLAY=:1 TERM=xterm-256color
OUT=${OUT:-/tmp/chk}
PASSWORD=${DEVBOX_PASSWORD:-devbox}
rm -rf "$OUT"; mkdir -p "$OUT"
fails=0
pass() { printf 'PASS  %s\n' "$1"; }
fail() {
  printf 'FAIL  %s\n' "$1"
  fails=$((fails + 1))
}
nwin() { i3-msg -t get_tree | grep -o '"window":[0-9]\+' | wc -l; }
closeall() {
  pkill -u "$USER" -x wezterm-gui 2>/dev/null
  pkill -x rofi 2>/dev/null
  sleep 1
}
shot() { import -window root "$OUT/$1.png"; }

closeall

# 1. i3 config valid + reload
i3 -C -c ~/.i3/config >/dev/null 2>&1 && pass "i3 config validates (i3 -C)" || fail "i3 config validates"
i3-msg reload 2>&1 | grep -q true && pass "i3 reload via i3-msg" || fail "i3 reload"

# 2. Mod+Return opens terminal
before=$(nwin)
xdotool key super+Return; sleep 6
after=$(nwin)
[ "$after" -gt "$before" ] && pass "Mod+Return opens a terminal ($before -> $after windows)" || fail "Mod+Return opens terminal"
shot 1-terminal

# 3. fullscreen toggle
xdotool key super+f; sleep 1
i3-msg -t get_tree | grep -q '"fullscreen_mode":1' && pass "Mod+f fullscreen" || fail "Mod+f fullscreen"
xdotool key super+f; sleep 1

# 4. second terminal tiles
xdotool key super+Return; sleep 6
shot 2-tiled
[ "$(nwin)" -ge $((after + 1)) ] && pass "second terminal tiles next to first" || fail "second terminal tiles"

# 5. workspace switch
i3-msg workspace 2 >/dev/null; sleep 1
i3-msg -t get_workspaces | grep -q '"name":"2","visible":true\|"name":"2".*"focused":true' && pass "workspace 2 switch" || fail "workspace 2 switch"
xdotool key super+Return; sleep 6
shot 3-workspace2
i3-msg workspace 1 >/dev/null; sleep 1

# 6. rofi launcher via Mod+d
closeall
xdotool key super+d; sleep 3
pgrep -x rofi >/dev/null && pass "Mod+d opens rofi" || fail "Mod+d opens rofi"
xdotool type --delay 80 "wez"; sleep 2
shot 4-rofi-filter
xdotool key Escape; sleep 1

# 7. screenshot key
rm -f ~/Pictures/*.png 2>/dev/null
xdotool key Print; sleep 3
if find ~ -newer "$OUT/1-terminal.png" -name '*.png' -not -path "$OUT/*" -not -path '*/.cache/*' -not -path '*/nvim/*' 2>/dev/null | grep -q .; then
  pass "Print key saves a screenshot"
else
  fail "Print key saves a screenshot"
fi

# 8. polybar modules respond
polybar-msg cmd hide >/dev/null 2>&1; polybar-msg cmd show >/dev/null 2>&1 && pass "polybar ipc (hide/show)" || fail "polybar ipc"
for s in ~/bin/system/polybar-*-status.sh; do
  [ -x "$s" ] || continue
  name=$(basename "$s")
  # nordvpn runs forever in polybar "tail" mode unless told to print once.
  out=$(timeout 5 bash "$s" --once 2>&1 | head -1); rc=${PIPESTATUS[0]}
  # faillock prints nothing when there are no failed logins; that is healthy.
  if [ "$rc" -ne 0 ]; then
    fail "$name exited $rc"
  elif [ -n "$out" ] || [ "$name" = polybar-faillock-status.sh ]; then
    pass "$name -> ${out:-(empty, nothing to warn about)}"
  else
    fail "$name produced no output"
  fi
done

# 9. lock screen: lock, screenshot, unlock with tester's password
closeall
bash ~/bin/system/lock.sh >/dev/null 2>&1 &
sleep 5
pgrep -x i3lock >/dev/null && pass "lock.sh starts i3lock" || fail "lock.sh starts i3lock"
shot 5-locked
xdotool type --delay 100 "$PASSWORD"; xdotool key Return; sleep 3
pgrep -x i3lock >/dev/null && fail "unlock with password" || pass "unlock with password"

# 10. notifications
eval "$(dbus-launch --sh-syntax)"
pgrep -x dunst >/dev/null || { dunst -config ~/.config/dunst/dunstrc >/dev/null 2>&1 & sleep 2; }
notify-send "check" "notify ok" && pass "notify-send" || fail "notify-send"
sleep 1; shot 6-notify

# 11. nvim: LSP, formatting, treesitter, telescope
cd "${REPO:-$PWD}" || exit 1
cat >/tmp/lsp.lua <<'EOF'
vim.defer_fn(function()
  local names = {}
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do names[#names + 1] = c.name end
  io.write("LSP:" .. table.concat(names, ",") .. "\n")
  io.write("TS:" .. tostring(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil) .. "\n")
  vim.cmd("qa!")
end, 12000)
EOF
printf 'local x = 1\nprint(x)\n' >/tmp/a.lua
printf '#!/usr/bin/env bash\necho hi\n' >/tmp/a.sh
printf 'package main\nfunc main() {}\n' >/tmp/a.go
for f in /tmp/a.lua /tmp/a.sh /tmp/a.go; do
  r=$(nvim --headless "$f" -S /tmp/lsp.lua 2>&1 | tr '\n' ' ')
  echo "INFO  nvim $f -> $r"
done
printf 'local   x=1\n' >/tmp/f.lua
nvim --headless /tmp/f.lua "+lua require('conform').format({async=false})" +wq 2>/dev/null
[ "$(cat /tmp/f.lua)" = "local x = 1" ] && pass "nvim conform formats lua (stylua)" || fail "nvim conform formats lua"
nvim --headless "+lua local ok=pcall(require('telescope').load_extension,'fzf'); io.write('FZF:'..tostring(ok)..'\n')" +qa 2>&1 | grep -q 'FZF:true' && pass "telescope fzf native loads" || fail "telescope fzf native loads"

# 12. repo checks
for t in test-links test-aws-keepalive test-tmux test-ai-aliases; do
  make -s $t >/tmp/$t.out 2>&1 && pass "make $t" || fail "make $t"
done
closeall
echo "DONE ($fails failed)"
exit "$fails"
