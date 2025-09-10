output "lambda" {
  description = <<-DESCRIPTION
  Output ARNs for the resulting cirrus task lambda resources.
  DESCRIPTION

  value = {
    function_arn = one(aws_lambda_function.task[*].arn)
    role_arn     = one(aws_iam_role.task_lambda[*].arn)
    resolved_ecr_image_digest = (
      local.lambda_resolve_ecr_tag_to_digest
      ? data.aws_ecr_image.lambda_task_image[0].image_digest
      : null
    )
  }
}

output "batch" {
  description = <<-DESCRIPTION
  Output ARNs for the resulting cirrus task batch resources.
  DESCRIPTION

  value = {
    job_queue_arn      = try(local.batch_compute_config.job_queue_arn, null)
    job_definition_arn = one(aws_batch_job_definition.task[*].arn)
    role_arn           = one(aws_iam_role.task_batch[*].arn)
    resolved_ecr_image_digest = (
      local.batch_resolve_ecr_tag_to_digest
      ? data.aws_ecr_image.batch_task_image[0].image_digest
      : null
    )
  }
}
