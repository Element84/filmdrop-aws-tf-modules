data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

data "archive_file" "user_init_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/user_init"
  output_path = "${path.module}/user_init_lambda_zip.zip"
}
