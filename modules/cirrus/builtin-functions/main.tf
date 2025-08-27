locals {
  cirrus_lambda_filename = "${path.root}/cirrus-lambda-dist-${var.cirrus_lambda_version}.zip"
}

resource "null_resource" "get_cirrus_lambda" {
  triggers = {
    always_run = var.cirrus_lambda_version
  }
  provisioner "local-exec" {
    command = "curl -s -L -o ${local.cirrus_lambda_filename} https://github.com/cirrus-geo/cirrus-geo/releases/download/v${var.cirrus_lambda_version}/cirrus-lambda-dist.zip"
  }
}
