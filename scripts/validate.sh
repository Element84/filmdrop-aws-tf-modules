#!/usr/bin/env bash
set -Eeuo pipefail
# set -x # print each command before executing

for x in *; do
  (cd "$x" && terraform init -input=false && terraform validate -no-color)
done
