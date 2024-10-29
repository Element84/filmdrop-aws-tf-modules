module "tasks" {
  # TODO - CVG - input validation?
  #  - Names must be unique
  source = "./tasks"
  for_each = {
    for _, task in var.cirrus_tasks :
    task.name => task
  }

  cirrus_prefix          = local.cirrus_prefix
  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids
  warning_sns_topic_arn  = var.warning_sns_topic_arn
  critical_sns_topic_arn = var.critical_sns_topic_arn
  task_config            = each.value
}

module "workflows" {
  # TODO - CVG - input validation?
  #  - Requires one or more tasks to exist
  #  - Names must be unique
  #  - Variable naming
  source = "./workflows"
  for_each = {
    for index, workflow in var.cirrus_workflows :
    workflow.name => workflow
  }
  depends_on = [module.tasks]

  cirrus_prefix   = local.cirrus_prefix
  cirrus_tasks    = module.tasks
  workflow_config = each.value
}