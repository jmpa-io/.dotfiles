#!/usr/bin/env bash
# This script lists all the DNS entries in Tailscale.

# funcs.
die() { echo "$1"; exit "${2:-1}"; }

# check deps.
deps=("aws" "curl")
for dep in "${deps[@]}"; do hash "$dep" || missing+=("$dep"); done
if [[ "${#missing[*]}" -gt 0 ]]; then
  [[ "${#missing}" -gt 1 ]] && s="s"
  die "missing dep${s}: ${missing[*]}"
fi

# check auth.
aws sts get-caller-identity &>/dev/null \
  || die "unable to connect to AWS; are you authed?"

# pull Tailscale API token.
token=$(aws ssm get-parameter --name "/homelab/tailscale/tokens/api-token" \
  --query "Parameter.Value" --output text \
  --with-decryption 2>/dev/null) \
  || die "failed to get Tailscale API token from paramstore"

# list DNS nameservers.
curl -X GET https://api.tailscale.com/api/v2/tailnet/-/dns/nameservers \
  -H "Authorization: Bearer $token" \
  || die "failed to list Tailscale DNS nameservers"

