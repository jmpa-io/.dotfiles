#!/usr/bin/env bash
# This script uploads obsidian files to Google Drive, using rclone.

# funcs.
die() { echo "$1" >&2; exit "${2:-1}"; }

# check deps.
deps=("rclone")
for dep in "${deps[@]}"; do hash "$dep" 2>/dev/null || missing+=("$dep"); done
if [[ "${#missing[@]}" -gt 0 ]]; then
  s=""; [[ "${#missing[@]}" -gt 1 ]] && s="s"
  die "missing dep${s}: ${missing[*]}"
fi

# check vault.
vault="$HOME/obsidian/My vault./"
[[ -d "$vault" ]] || \
  die "missing $vault"

# upload to Google Drive.
rclone copy "$vault" "google drive": \
  --drive-server-side-across-configs \
  || die "failed to upload $vault to Google Drive"
