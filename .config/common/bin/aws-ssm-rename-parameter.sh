#!/usr/bin/env bash
# This script renames an AWS SSM parameter.

# funcs.
die() { echo "$1" >&2; exit "${2:-1}"; }
usage() { echo "usage: $0 <old-name> <new-name>"; exit 64; }
diejq() { echo "$1:" >&2; jq '.' <<< "$2"; exit "${3:-1}"; }

# check deps.
deps=(aws jq)
for dep in "${deps[@]}"; do
  hash "$dep" 2>/dev/null || missing+=("$dep")
done
if [[ ${#missing[@]} -ne 0 ]]; then
  s=""; [[ ${#missing[@]} -gt 1 ]] && { s="s"; }
  die "missing dep${s}: ${missing[*]}"
fi

# check args.
old="$1"
new="$2"
[[ -z "$old" || -z "$new" ]] && usage

# check aws auth.
aws sts get-caller-identity &>/dev/null \
  || die "unable to connect to AWS; are you authed?"

# retrieve parameter.
resp=$(aws ssm get-parameter \
  --name "$old" \
  --with-decryption \
  --output json 2>/dev/null) \
  || die "failed to retrieve parameter: $old"

[[ $(<<< "$resp" jq '.Parameter') == null ]] \
  && diejq "invalid response retrieving parameter $old" "$resp"

# parse fields.
paramValue=$(<<< "$resp" jq -r '.Parameter.Value') \
  || die "failed to parse parameter value"
paramType=$(<<< "$resp" jq -r '.Parameter.Type') \
  || die "failed to parse parameter type"

# create new parameter.
aws ssm put-parameter \
  --name "$new" \
  --value "$paramValue" \
  --type "$paramType" \
  --overwrite >/dev/null \
  || die "failed to create new parameter: $new"

# delete old parameter.
aws ssm delete-parameter \
  --name "$old" >/dev/null \
  || die "failed to delete old parameter: $old"

echo "renamed $old -> $new"
