#!/usr/bin/env bash
# Migrates ~/work to ~/.dotfiles.d/work.
#
# What it does:
#   1. Copies ~/work to ~/.dotfiles.d/work (if not already there).
#   2. Backs up ~/work to ~/work.bak.
#   3. Removes ~/work.
#   4. Updates any source ~/work references in ~/.zshenv and ~/.zshrc.
#
# Safe to run multiple times — skips steps that are already done.

set -e

die() {
  echo "error: $1" >&2
  exit "${2:-1}"
}

info() { echo "  $1"; }

SRC="$HOME/work"
DEST="$HOME/.dotfiles.d/work"
BAK="$HOME/work.bak"

# 1. Nothing to do if ~/work doesn't exist.
if [[ ! -f "$SRC" ]]; then
  info "~/work not found — nothing to migrate."
  exit 0
fi

# 2. Copy to ~/.dotfiles.d/work if not already there.
if [[ -f "$DEST" ]]; then
  info "~/.dotfiles.d/work already exists — skipping copy."
else
  mkdir -p "$HOME/.dotfiles.d"
  cp "$SRC" "$DEST"
  chmod 600 "$DEST"
  info "copied ~/work -> ~/.dotfiles.d/work"
fi

# 3. Back up and remove ~/work.
if [[ -f "$SRC" ]]; then
  cp "$SRC" "$BAK"
  chmod 600 "$BAK"
  rm "$SRC"
  info "backed up ~/work -> ~/work.bak and removed ~/work"
fi

# 4. Update source references in shell init files.
# Replaces: source ~/work, source $HOME/work, . ~/work, . $HOME/work
# With the ~/.dotfiles.d/work equivalent.
for f in "$HOME/.zshenv" "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
  [[ -f "$f" ]] || continue

  # Match any sourcing of ~/work or $HOME/work (not already dotfiles.d).
  if grep -qE '(source|\.) +(~|\$HOME)/work($| )' "$f"; then
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' -E 's|(source|\.) +(~|\$HOME)/work($| )|\1 \$HOME/.dotfiles.d/work\3|g' "$f"
    else
      sed -i -E 's|(source|\.) +(~|\$HOME)/work($| )|\1 \$HOME/.dotfiles.d/work\3|g' "$f"
    fi
    info "updated source reference in $f"
  fi
done

echo ""
echo "done. re-source your shell or open a new terminal to pick up the change."
echo "once confirmed working, you can remove the backup: rm ~/work.bak"
