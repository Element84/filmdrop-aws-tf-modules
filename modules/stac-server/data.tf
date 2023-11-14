data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

data "archive_file" "user_init_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/user_init"
  output_path = "${path.module}/user_init_lambda_zip.zip"
  depends_on = [
    random_string.user_init_lambda_zip_poke
  ]
}

# this forces the user_init_lambda_zip to always be built
resource "random_string" "user_init_lambda_zip_poke" {
  length  = 16
  special = false
}
