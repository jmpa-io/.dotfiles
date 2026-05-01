#!/usr/bin/env bash
# Lists all the names of AWS SSM Parameters in the authed AWS account.

# funcs.
die() { echo "$1" >&2; exit "${2:-1}"; }

# check deps.
deps=("aws" "jq")
for dep in "${deps[@]}"; do hash "$dep" 2>/dev/null || missing+=("$dep"); done
if [[ ${#missing[@]} -ne 0 ]]; then
  s=""; [[ ${#missing[@]} -gt 1 ]] && s="s"
  die "missing dep${s}: ${missing[*]}"
fi

# check auth.
aws sts get-caller-identity &>/dev/null \
  || die "unable to connect to AWS; are you authed?"

# list all parameters, handling pagination.
next=""
while true; do
  if [[ -n "$next" ]]; then
    resp=$(aws ssm describe-parameters --next-token "$next")
  else
    resp=$(aws ssm describe-parameters)
  fi
  jq -r '.Parameters[].Name' <<< "$resp"
  next=$(jq -r '.NextToken // empty' <<< "$resp")
  [[ -z "$next" ]] && break
done
