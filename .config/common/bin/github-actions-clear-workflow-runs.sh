#!/usr/bin/env bash
# clears all GitHub Action runs for a given GitHub repository.

# funcs.
die() { echo "$1" >&2; exit "${2:-1}"; }
usage() { echo "usage: $0 <org/repo>"; exit 64; }

# check deps.
deps=(curl jq)
for dep in "${deps[@]}"; do
  hash "$dep" 2>/dev/null || missing+=("$dep")
done
if [[ ${#missing[@]} -ne 0 ]]; then
  s=""; [[ ${#missing[@]} -gt 1 ]] && s="s"
  die "missing dep${s}: ${missing[*]}"
fi

# check args.
repo="$1"
[[ -z "$repo" ]] && usage

# retrieve GitHub token.
token="$GITHUB_TOKEN"
if [[ -z "$token" && -z "$GITHUB_ACTION" ]]; then
  aws sts get-caller-identity &>/dev/null \
    || die "unable to connect to AWS; are you authed?"
  token=$(aws ssm get-parameter --name "/tokens/github" \
    --query "Parameter.Value" --output text \
    --with-decryption 2>/dev/null) \
    || die "failed to get GitHub token from paramstore"
fi
[[ -z "$token" ]] \
  && die "missing \$GITHUB_TOKEN"

# retrieve and delete ALL action runs, handling pagination.
page=1
while true; do
  resp=$(curl -s "https://api.github.com/repos/$repo/actions/runs?per_page=100&page=$page" \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: bearer $token") \
    || die "failed to retrieve $repo action runs (page $page)"

  ids=$(jq -r '.workflow_runs[].id' <<< "$resp") \
    || die "failed to parse response for $repo action runs (page $page)"

  # no more runs — done.
  [[ -z "$ids" ]] && break

  for id in $ids; do
    curl -X DELETE -s "https://api.github.com/repos/$repo/actions/runs/$id" \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: bearer $token" \
      || die "failed to delete $repo action run $id"
  done

  (( page++ ))
done
