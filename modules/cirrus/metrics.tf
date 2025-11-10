module "metrics" {
  count  = var.cirrus_workflow_metrics_enabled ? 1 : 0
  source = "./metrics"

  resource_prefix = var.resource_prefix
}
