#!/usr/bin/env bash

# Update the cirrus lambda dist zip.
#
# Usage:
#
#     ./scripts/update-cirrus-lambda-dist.bash vX.Y.Z
#
# or
#
#     export CIRRUS_TAG=vX.Y.Z
#     ./scripts/update-cirrus-lambda-dist.bash

set -euo pipefail


CIRRUS_LAMBDA_DIST_PATH="modules/cirrus/cirrus-lambda-dist.zip"


find_this () {
    THIS="${1:?'must provide script path, like "${BASH_SOURCE[0]}" or "$0"'}"
    trap "echo >&2 'FATAL: could not resolve parent directory of ${THIS}'" EXIT
    [ "${THIS:0:1}"  == "/" ] || THIS="$(pwd -P)/${THIS}"
    THIS_DIR="$(dirname -- "${THIS}")"
    THIS_DIR="$(cd -P -- "${THIS_DIR}" && pwd)"
    THIS="${THIS_DIR}/$(basename -- "${THIS}")"
    trap "" EXIT
}


main() {
    find_this "${BASH_SOURCE[0]}"

    local cirrus_tag output
    cirrus_tag="${1:-"${CIRRUS_TAG:-}"}"
    output="${THIS_DIR}/../${CIRRUS_LAMBDA_DIST_PATH}"

    [ -n "${cirrus_tag}" ] || {
        echo "ERROR: CIRRUS_TAG is not set in the environment and is not provided on the command line."
        echo "Usage: ${BASH_SOURCE[0]} [CIRRUS_TAG]"
        exit 1
    }

    echo "Downloading cirrus ${cirrus_tag} to ${output}..."
    curl -Lfs -o "${output}" "https://github.com/cirrus-geo/cirrus-geo/releases/download/${cirrus_tag}/cirrus-lambda-dist.zip"
    echo "Done!"
}


main "$@"
