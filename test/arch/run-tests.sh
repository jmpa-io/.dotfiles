#!/usr/bin/env bash
# Runs inside the container. The repo is at $SRC (default /src, mounted read-only); each run
# copies it to ~/.dotfiles so every run starts pristine.
# Each step prints PASS/FAIL; the exit code is the number of failed steps.
# shellcheck disable=SC2016  # the inner 'bash -c' shells must expand $HOME, not this one.
set -u
fails=0
step() {
  local name="$1"
  shift
  echo
  echo "=== $name"
  if "$@"; then echo "PASS: $name"; else
    echo "FAIL: $name"
    fails=$((fails + 1))
  fi
}

cp -r "${SRC:-/src}" ~/.dotfiles && cd ~/.dotfiles || exit 99

step "pacman sync" sudo pacman -Syu --noconfirm
step "configure-bin" make configure-bin
step "configure-common leaves the repo clean" bash -c 'before=$(find .config/common/bin -type l | wc -l); make configure-common >/dev/null; after=$(find .config/common/bin -type l | wc -l); echo "symlinks inside the repo bin dir: $before -> $after"; [ "$before" = "$after" ]'
step "install-desktop (packages + AUR)" make install-desktop
step "configure-desktop" make configure-desktop
step "configure-i3" make configure-i3
step "configure-polybar" make configure-polybar
step "configure-picom" make configure-picom
step "configure-system" make configure-system
step "configure-system is idempotent" bash -c 'make configure-system | grep -qv installed'
step "i3 config validates" i3 -C -c "$HOME/.i3/config"
step "scripts pass shellcheck" bash -c 'shellcheck .config/common/bin/system/*.sh'
step "scripts: i3exit dry-run" bash -c 'I3EXIT_DRY_RUN=1 "$HOME/bin/system/i3exit.sh" suspend'
step "scripts: faillock label runs" bash -c '"$HOME/bin/system/polybar-faillock-status.sh"; true'

step "desktop smoke test (headless i3/polybar/dunst)" bash "$HOME/.dotfiles/test/arch/desktop-smoke.sh"

echo
echo "=== SUMMARY: $fails step(s) failed"
exit "$fails"
