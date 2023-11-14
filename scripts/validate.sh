#!/usr/bin/env bash
set -xEeuo pipefail

for x in *; do
  if [[ "${x}" == "mosaic-titiler" ]]; then
    # the validate step was never meant for a raw module, it only happens to work for
    # modules that don't have multiple required providers
    # this script also doesn't recurse past the first level, so it would also fail
    # in a bunch of cloudfront modules ft this script even worked correctly -
    # for now, punt if the module needs an aws.east provider like mosaic-titiler
    continue
  fi
  cd "$x"
  terraform init -input=false
  terraform validate -no-color
  cd -
done
