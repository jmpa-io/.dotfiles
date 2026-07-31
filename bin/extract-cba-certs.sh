#!/usr/bin/env bash
# extracts CBA root CA certs from the macOS System keychain into dist/cba-certs/.

set -e

# Funcs.
die() { echo "$1" >&2; exit "${2:-1}"; }

# Check deps.
deps=(security openssl)
missing=()
for dep in "${deps[@]}"; do hash "$dep" 2>/dev/null || missing+=("$dep"); done
if [[ ${#missing[@]} -ne 0 ]]; then
  [[ "${#missing[@]}" -gt 1 ]] && s="s"
  die "Missing dep${s}: ${missing[*]}."
fi

# Vars.
[[ "$(uname)" == "Darwin" ]] || die "cert extraction requires macOS — run on a CBA-managed Mac."
keychain="/Library/Keychains/System.keychain"
outDir="${REPO_ROOT:-$(pwd)}/dist/cba-certs"

mkdir -p "$outDir"

# Extract.
# Each entry: "cert name in keychain" → output filename.
# Certs required by Docker builds to trust the CBA Prisma proxy (which intercepts
# HTTPS and re-signs with CBA certificates) and Artifactory (artifactory.internal.cba).
declare -A certs=(
  ["prisma2026ecdsa.cba"]="cba-cert-prisma-ecdsa.crt"
  ["prisma2026rsa.cba"]="cba-cert-prisma-rsa.crt"
  ["CBA Group Root CA G3"]="cba-cert-group-root-g3.crt"
  ["CBAInternalRootCA"]="cba-cert-internal-root-ca.crt"
)

for name in "${!certs[@]}"; do
  file="${certs[$name]}"
  outPath="$outDir/$file"

  security find-certificate -c "$name" -p "$keychain" 2>/dev/null >"$outPath"

  [[ -s "$outPath" ]] || {
    rm -f "$outPath"
    die "cert '$name' not found in $keychain — are you on a CBA-managed Mac?"
  }

  openssl x509 -in "$outPath" -noout 2>/dev/null ||
    die "cert '$name' extracted but is not valid PEM."

  subject=$(openssl x509 -in "$outPath" -noout -subject 2>/dev/null |
    awk -F'CN *= *' '{print $2}')
  echo "  [ok] $file  ($subject)"
done

echo "  written to dist/cba-certs/"
