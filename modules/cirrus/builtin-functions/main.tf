locals {
  cirrus_python_version = var.cirrus_python_version

  # If the user has provided a local zip, the filename is simply that; importantly, if they are not, we include the
  # version in the filename to ensure an update is forced when the version changes
  cirrus_lambda_filename = var.cirrus_lambda_zip_filepath != null ? "${path.root}/${var.cirrus_lambda_zip_filepath}" : "${path.root}/cirrus-lambda-dist-${var.cirrus_lambda_version}.zip"

  # If the user has provided a local zip, here we hash it in order to force an update when contents of the zip change
  cirrus_lambda_zip_hash = var.cirrus_lambda_zip_filepath != null ? filebase64sha256("${path.root}/${var.cirrus_lambda_zip_filepath}") : null
}

# Download the Cirrus zip iff the user has not provided a local zip. Re-download if the version changes.
resource "null_resource" "get_cirrus_lambda" {
  count = var.cirrus_lambda_zip_filepath == null ? 1 : 0
  triggers = {
    always_run = var.cirrus_lambda_version
  }
  provisioner "local-exec" {
    command = "curl -s -L -o ${local.cirrus_lambda_filename} --fail https://github.com/cirrus-geo/cirrus-geo/releases/download/v${var.cirrus_lambda_version}/cirrus-lambda-dist_v${var.cirrus_lambda_version}_python-${local.cirrus_python_version}_aarch64.zip"
  }
}
