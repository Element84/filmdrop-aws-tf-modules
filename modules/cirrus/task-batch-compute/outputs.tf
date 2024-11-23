output "batch" {
  value = {
    compute_environment_arn = coalesce(
      one(data.aws_batch_compute_environment.task_batch[*].arn),
      one(aws_batch_compute_environment.task_batch[*].arn)
    )
    compute_environment_is_fargate = (
      local.create_compute_environment
      ? local.compute_environment_is_fargate
      : var.batch_compute_config.batch_compute_environment_existing.is_fargate
    )
    ecs_task_execution_role_arn = one(
      aws_iam_role.task_ecs[*].arn
    )
    job_queue_arn = coalesce(
      one(data.aws_batch_job_queue.task_batch[*].arn),
      one(aws_batch_job_queue.task_batch[*].arn)
    )
  }
}
