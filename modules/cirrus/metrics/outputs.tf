output "cirrus_workflow_metrics_log_group_name" {
  description = "CloudWatch LogGroup for Cirrus Workflow Metrics"
  value       = aws_cloudwatch_log_group.workflow_events.name
}

output "cirrus_workflow_metrics_namespace" {
  description = "CloudWatch Metrics namespace for Cirrus Workflow Metrics"
  value       = "${var.resource_prefix}-workflow"
}
