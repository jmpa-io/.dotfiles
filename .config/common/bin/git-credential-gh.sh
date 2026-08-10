#!/usr/bin/env bash
# Git credential helper that returns a token for a specific GitHub account.
# GH_CREDENTIAL_USER must be set by the caller (via gitconfig credential.helper).
case "$1" in
  get)
    echo "protocol=https"
    echo "host=github.com"
    echo "username=${GH_CREDENTIAL_USER}"
    echo "password=$(gh auth token --user "${GH_CREDENTIAL_USER}")"
    ;;
esac
