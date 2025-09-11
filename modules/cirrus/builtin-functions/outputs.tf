output "pre_batch_lambda_function_arn" {
  value = aws_lambda_function.cirrus_pre_batch.arn
}

output "post_batch_lambda_function_arn" {
  value = aws_lambda_function.cirrus_post_batch.arn
}

output "cirrus_lambda_version" {
  value = var.cirrus_lambda_zip_filepath == null ? var.cirrus_lambda_version : "unknown"
}
