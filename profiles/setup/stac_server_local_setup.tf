
# Sets up artifacts for a local stac server deploy
resource "null_resource" "stac_server_local_artifact_setup" {
  count = var.deploy_local_stac_server_artifacts && var.stac_server_version != "" ? 1 : 0
  triggers = {
    stac_server_version = var.stac_server_version
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-ec"]
    command     = <<EOF
export STAC_SERVER_TAG=${var.stac_server_version}
export STAC_SERVER_DIR="stac-server-$${STAC_SERVER_TAG:1}"
source $HOME/.nvm/nvm.sh
nvm install v18
nvm use v18
echo "Building stac-server..."
curl -L -f --no-progress-meter -o - "https://github.com/stac-utils/stac-server/archive/refs/tags/$${STAC_SERVER_TAG}.tar.gz" | tar -xz
cd "$STAC_SERVER_DIR"
npm install
BUILD_PRE_HOOK=true npm run build
mkdir -p ../modules/stac-server/lambda/api
cp dist/api/api.zip ../modules/stac-server/lambda/api/
mkdir -p ../modules/stac-server/lambda/ingest
cp dist/ingest/ingest.zip ../modules/stac-server/lambda/ingest/
mkdir -p ../modules/stac-server/lambda/pre-hook
cp dist/pre-hook/pre-hook.zip ../modules/stac-server/lambda/pre-hook/
cd ..
cd modules/stac-server/historical-ingest/lambda/
pip install -r requirements.txt --target package
cd package
zip -r ../../lambda.zip .
cd ../
zip ../lambda.zip main.py
cd ../../../../
EOF
  }
}
