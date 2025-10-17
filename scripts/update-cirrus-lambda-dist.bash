#!/usr/bin/env bash

# Update the Cirrus lambda dist zip.
# Note: each Cirrus lambda zip version runs on a specific Python version, so you must also specify
# the correct Python version it requires. 
#
# Usage:
#
#     ./scripts/update-cirrus-lambda-dist.bash vX.Y.Z a.bc
#
# or
#
#     export CIRRUS_TAG=vX.Y.Z CIRRUS_PY_VERSION=a.bc
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

    local cirrus_tag cirrus_py_version output
    cirrus_tag="${1:-"${CIRRUS_TAG:-}"}"
    cirrus_py_version="${2:-"${CIRRUS_PY_VERSION:-}"}"
    output="${THIS_DIR}/../${CIRRUS_LAMBDA_DIST_PATH}"
    filename="https://github.com/cirrus-geo/cirrus-geo/releases/download/${cirrus_tag}/cirrus-lambda-dist_${cirrus_tag}_python-${cirrus_py_version}_aarch64.zip"

    [ -n "${cirrus_tag}" ] || {
        echo "ERROR: CIRRUS_TAG is not set in the environment and is not provided on the command line."
        echo "Usage: ${BASH_SOURCE[0]} [CIRRUS_TAG] [CIRRUS_PY_VERSION]"
        exit 1
    }

    [ -n "${cirrus_py_version}" ] || {
        echo "ERROR: CIRRUS_PY_VERSION is not set in the environment and is not provided on the command line."
        echo "Usage: ${BASH_SOURCE[0]} [CIRRUS_TAG] [CIRRUS_PY_VERSION]"
        exit 1
    }

    echo "Downloading cirrus ${cirrus_tag} (Python ${cirrus_py_version}) to ${output}..."
    if curl -Lfs -o "${output}" "${filename}"; then
        echo "Done!"
    else
        echo "ERROR: Failed to download cirrus: ${filename}"
        exit 1
    fi
}


main "$@"
