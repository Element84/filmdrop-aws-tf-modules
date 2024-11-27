output "lambda" {
  value = {
    function_arn = one(aws_lambda_function.task[*].arn)
  }
}

output "batch" {
  value = {
    job_queue_arn      = try(local.batch_compute_config.job_queue_arn, null)
    job_definition_arn = one(aws_batch_job_definition.task[*].arn)
  }
}