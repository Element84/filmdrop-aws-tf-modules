output "lambda" {
  description = <<-DESCRIPTION
  Output ARNs for the resulting cirrus task lambda resources.
  DESCRIPTION

  value = {
    function_arn = one(aws_lambda_function.task[*].arn)
  }
}

output "batch" {
  description = <<-DESCRIPTION
  Output ARNs for the resulting cirrus task batch resources.
  DESCRIPTION

  value = {
    job_queue_arn      = try(local.batch_compute_config.job_queue_arn, null)
    job_definition_arn = one(aws_batch_job_definition.task[*].arn)
  }
}
