#!/usr/bin/env bash
# Prints the bash/sh scripts in this repo (one per line) for `make lint-sh` and
# `make format`: *.sh files plus extensionless files with a bash/sh shebang.
# zsh scripts (shellcheck can't parse them) and vendored directories are skipped.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Tracked plus new-but-not-ignored files, so unstaged work is linted too.
git ls-files -z --cached --others --exclude-standard | while IFS= read -r -d '' f; do
  case "$f" in
  .config/neovim/* | .config/tmux/plugins/* | fonts/* | wallpapers/* | docs/*.png) continue ;;
  esac
  [[ -f $f && ! -L $f ]] || continue

  first=$(head -n1 "$f" 2>/dev/null | LC_ALL=C tr -d '\000' || true)
  case "$first" in
  '#!'*zsh*) ;;
  '#!'*bash* | '#!'*' sh' | '#!/bin/sh'* | '#!'*dash*) echo "$f" ;;
  *)
    if [[ $f == *.sh ]]; then echo "$f"; fi
    ;;
  esac
done
