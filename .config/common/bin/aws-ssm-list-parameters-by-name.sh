#!/usr/bin/env bash
# Lists all the names of AWS SSM Parameters in the authed AWS account.

aws ssm describe-parameters | jq -r '.Parameters[].Name'

