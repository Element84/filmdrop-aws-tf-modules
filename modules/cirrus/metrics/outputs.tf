output "workflow_metrics_cloudwatch_log_group_name" {
  description = "CloudWatch LogGroup for Cirrus Workflow Metrics"
  value       = aws_cloudwatch_log_group.workflow_events.name
}

output "workflow_metrics_cloudwatch_namespace" {
  description = "CloudWatch Metrics namespace for Cirrus Workflow Metrics"
  value       = "${var.resource_prefix}-workflow"
}

output "workflow_metrics_cloudwatch_write_policy_arn" {
  description = "ARN of the IAM policy for allowing writes to the Cirrus Workflow Metrics Log Group"
  value       = aws_iam_policy.workflow_metrics_cloudwatch_write_policy.arn
}

output "workflow_metrics_cloudwatch_read_policy_arn" {
  description = "ARN of the IAM policy for allowing reads to the Cirrus Workflow Metrics Namespace"
  value       = aws_iam_policy.workflow_metrics_cloudwatch_read_policy.arn
}
