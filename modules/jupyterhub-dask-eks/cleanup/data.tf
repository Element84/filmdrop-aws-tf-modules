data "aws_region" "current" {
}

data "archive_file" "cleanup_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/cleanup"
  output_path = "${path.module}/cleanup_lambda_zip.zip"
}

data "archive_file" "notifications_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/notifications"
  output_path = "${path.module}/notifications_lambda_zip.zip"
}
