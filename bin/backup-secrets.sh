#!/usr/bin/env bash
#
# Bundle secrets that must NOT live in git into one encrypted archive.
# Usage: bin/backup-secrets.sh [output-dir]   (default: $HOME)
# Restore: gpg -d secrets-*.tar.gpg | tar -xvf - -C "$HOME"
set -euo pipefail
umask 077

out_dir="${1:-$HOME}"
out="$out_dir/secrets-$(date +%Y%m%d).tar.gpg"

command -v gpg >/dev/null || {
  echo "gpg is required (pacman -S gnupg)" >&2
  exit 1
}

# Paths relative to $HOME. Missing ones are skipped.
candidates=(
  .ssh/id_ed25519 .ssh/id_ed25519.pub
  .ssh/homelab_k3s .ssh/homelab_k3s.pub
  .ssh/config .ssh/known_hosts
  .aws .kube kubeconfig
  .config/gcloud .config/gh .config/rclone
  .gitconfig-personal
  .local/share/keyrings
  .config/deluge/auth .config/deluge/ssl
  .claude.json
)

cd "$HOME"
existing=()
for p in "${candidates[@]}"; do
  [[ -e $p ]] && existing+=("$p")
done

echo "Archiving ${#existing[@]} paths -> $out"
printf '  %s\n' "${existing[@]}"

tar -cf - "${existing[@]}" | gpg --symmetric --cipher-algo AES256 --output "$out"
echo "Done. Copy $out to a USB drive or password manager, then delete the local copy."
