output "pre_batch_lambda_function_arn" {
  value = aws_lambda_function.cirrus_pre_batch.arn
}

output "post_batch_lambda_function_arn" {
  value = aws_lambda_function.cirrus_post_batch.arn
}
