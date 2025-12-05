module "metrics" {
  count  = var.workflow_metrics_cloudwatch_enabled ? 1 : 0
  source = "./metrics"

  resource_prefix = var.resource_prefix
}
