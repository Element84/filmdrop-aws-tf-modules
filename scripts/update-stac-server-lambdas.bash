#!/usr/bin/env bash

# Update the stac-server lambdas.
#
# Usage:
#
#     ./scripts/update-stac-server-lambdas.bash vX.Y.Z
#
# or
#
#     export STAC_SERVER_TAG=vX.Y.Z
#     ./scripts/update-stac-server-lambdas.bash

set -euo pipefail

if [ -z "${1:-}" ]; then
    if [ -z "${STAC_SERVER_TAG:-}" ]; then
        echo "ERROR: STAC_SERVER_TAG is not set in the environment and is not provided on the command line."
        echo "Usage: $0 [STAC_SERVER_TAG]"
        exit 1
    fi
else
    STAC_SERVER_TAG="$1"
fi
STAC_SERVER_DIR="stac-server-${STAC_SERVER_TAG:1}"

echo "Downloading stac-server $STAC_SERVER_TAG to $STAC_SERVER_DIR..."
curl -L -f --no-progress-meter -o stac-server.tgz "https://github.com/stac-utils/stac-server/archive/refs/tags/${STAC_SERVER_TAG}.tar.gz"
tar -xzf stac-server.tgz

echo "Building stac-server in $STAC_SERVER_DIR..."
(cd "$STAC_SERVER_DIR"; npm install; BUILD_PRE_HOOK=true npm run build)

echo "Copying stac-server lambdas..."
mkdir -p modules/stac-server/lambda/api
cp "$STAC_SERVER_DIR/dist/api/api.zip" modules/stac-server/lambda/api/
mkdir -p modules/stac-server/lambda/ingest
cp "$STAC_SERVER_DIR/dist/ingest/ingest.zip" modules/stac-server/lambda/ingest/
mkdir -p modules/stac-server/lambda/pre-hook
cp "$STAC_SERVER_DIR/dist/pre-hook/pre-hook.zip" modules/stac-server/lambda/pre-hook/

cd modules/stac-server/historical-ingest/lambda/
pip install -r requirements.txt --target package
cd package
zip -r ../../lambda.zip .
cd ../
zip ../lambda.zip main.py
cd ../../../../

echo "Done!"
