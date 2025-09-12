locals {
  cirrus_lambda_filename = var.cirrus_lambda_zip_filepath != null ? "${path.root}/${var.cirrus_lambda_zip_filepath}" : "${path.root}/cirrus-lambda-dist-${var.cirrus_lambda_version}.zip"
  cirrus_lambda_zip_hash = var.cirrus_lambda_zip_filepath != null ? filebase64sha256("${path.root}/${var.cirrus_lambda_zip_filepath}") : null
}

resource "null_resource" "get_cirrus_lambda" {
  count = var.cirrus_lambda_zip_filepath == null ? 1 : 0
  triggers = {
    always_run = var.cirrus_lambda_version
  }
  provisioner "local-exec" {
    command = "curl -s -L -o ${local.cirrus_lambda_filename} --fail https://github.com/cirrus-geo/cirrus-geo/releases/download/v${var.cirrus_lambda_version}/cirrus-lambda-dist.zip"
  }
}
