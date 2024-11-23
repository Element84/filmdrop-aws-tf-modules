locals {
  # Check if at least one task has a Batch configuration
  has_batch_task = anytrue([
    for task in coalesce(var.cirrus_tasks, []) :
    task.batch != null
  ])

  # Construct the full list of cirrus task configurations:
  # - User-defined tasks are always created
  # - If at least one Batch-style task was configured, pre-batch and post-batch
  #   tasks will be injected into the list of desired Cirrus tasks
  # - ...
  cirrus_tasks = concat(
    coalesce(var.cirrus_tasks, []),
    local.has_batch_task ? local.pre_batch_post_batch_task_configs : []
    # ... any future builtin tasks added here ...
  )

  # Construct the full map of builtin task template variables:
  # - If at least one Batch-style task was configured, the user may reference
  #   pre-batch and post-batch function ARNs using their builtin variable names
  # - ...
  builtin_task_template_variables = merge(
    local.has_batch_task ? local.pre_batch_post_batch_task_template_variables : {}
    # ... any future builtin task variables added here ...
  )
}

module "task_batch_compute" {
  source = "./task-batch-compute"
  for_each = {
    for compute in coalesce(var.cirrus_task_batch_compute, []) :
    compute.name => compute
  }

  cirrus_prefix          = local.cirrus_prefix
  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids
  batch_compute_config   = each.value
}

module "task" {
  source = "./task"
  for_each = {
    for task in local.cirrus_tasks :
    task.name => task
  }

  cirrus_prefix             = local.cirrus_prefix
  cirrus_payload_bucket     = var.cirrus_payload_bucket
  vpc_subnet_ids            = var.vpc_subnet_ids
  vpc_security_group_ids    = var.vpc_security_group_ids
  warning_sns_topic_arn     = var.warning_sns_topic_arn
  critical_sns_topic_arn    = var.critical_sns_topic_arn
  cirrus_task_batch_compute = module.task_batch_compute
  task_config               = each.value
}

module "workflow" {
  source = "./workflow"
  for_each = {
    for workflow in coalesce(var.cirrus_workflows, []) :
    workflow.name => workflow
  }

  cirrus_prefix                   = local.cirrus_prefix
  cirrus_tasks                    = module.task
  workflow_config                 = each.value
  builtin_task_template_variables = local.builtin_task_template_variables
}