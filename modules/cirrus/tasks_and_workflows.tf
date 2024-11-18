module "tasks_batch_compute" {
  source = "./tasks-batch-compute"
  for_each = {
    for _, compute in coalesce(var.cirrus_tasks_batch_compute, []) :
    compute.name => compute
  }

  cirrus_prefix          = local.cirrus_prefix
  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids
  batch_compute_config   = each.value
}

module "tasks" {
  source = "./tasks"
  for_each = {
    for _, task in coalesce(var.cirrus_tasks, []) :
    task.name => task
  }

  cirrus_prefix              = local.cirrus_prefix
  vpc_subnet_ids             = var.vpc_subnet_ids
  vpc_security_group_ids     = var.vpc_security_group_ids
  warning_sns_topic_arn      = var.warning_sns_topic_arn
  critical_sns_topic_arn     = var.critical_sns_topic_arn
  cirrus_tasks_batch_compute = module.tasks_batch_compute
  task_config                = each.value
}

module "workflows" {
  source = "./workflows"
  for_each = {
    for _, workflow in coalesce(var.cirrus_workflows, []) :
    workflow.name => workflow
  }

  cirrus_prefix   = local.cirrus_prefix
  cirrus_tasks    = module.tasks
  workflow_config = each.value
}