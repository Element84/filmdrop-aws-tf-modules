locals {
  # These variables may be used in task definition templates for convenience.
  builtin_task_definitions_variables = {
    CIRRUS_DATA_BUCKET = var.cirrus_data_bucket
  }

  # Construct Cirrus task-batch-compute, task, and workflow definitions.
  # These are loaded from YAML representations of each module's expected input
  # config HCL objects. This approach avoids having excessively long inline
  # config and promotes readability by enabling each item to be split into its
  # own file without environment-specific redundancy.
  #
  # Task YAML definitions are templated prior to HCL conversion to allow setting
  # any environment-specific values, including builtin variables defined above.
  #
  # Ternary defaults must be 'null' rather than an empty list since Terraform is
  # unable to implicitly typecast the complex config objects into a single type,
  # which would result in a type mismatch since tuple(n items) != list().
  cirrus_task_batch_compute_definitions = (
    var.cirrus_task_batch_compute_definitions_dir != null ? [
      for tbc_yaml in fileset(path.root, "${var.cirrus_task_batch_compute_definitions_dir}/**/definition.yaml") :
      yamldecode(file(tbc_yaml))
    ] : null
  )
  cirrus_task_definitions = (
    var.cirrus_task_definitions_dir != null ? [
      for task_yaml in fileset(path.root, "${var.cirrus_task_definitions_dir}/**/definition.yaml") :
      yamldecode(templatefile(task_yaml, merge(var.cirrus_task_definitions_variables, local.builtin_task_definitions_variables)))
    ] : null
  )
  cirrus_workflow_definitions = (
    var.cirrus_workflow_definitions_dir != null ? [
      for workflow_yaml in fileset(path.root, "${var.cirrus_workflow_definitions_dir}/**/definition.yaml") :
      yamldecode(file(workflow_yaml))
    ] : null
  )

  # Check if at least one task has a Batch configuration
  has_batch_task = (
    local.cirrus_task_definitions != null ? anytrue([
      for task in local.cirrus_task_definitions :
      try(task.batch, null) != null
    ]) : false
  )

  # Construct the full list of cirrus task configurations:
  # - User defined tasks are always created
  # - If at least one Batch-style task was configured, pre-batch and post-batch
  #   tasks will be injected into the list of desired Cirrus tasks
  merged_cirrus_task_definitions = (
    local.cirrus_task_definitions != null ? concat(
      local.cirrus_task_definitions,
      local.has_batch_task ? local.pre_batch_post_batch_task_configs : []
      # ... any future builtin tasks could be added here ...
    ) : null
  )
}

module "typed_definitions" {
  source = "./typed-definitions"

  # The definitions constructed from YAML files above are tuples. We need a list
  # of strictly-typed objects for variable-length module invocations below. This
  # module call simply typecasts the input definitions and outputs the results.
  # See that module's README for more information.
  cirrus_task_batch_compute = local.cirrus_task_batch_compute_definitions
  cirrus_tasks              = local.merged_cirrus_task_definitions
  cirrus_workflows          = local.cirrus_workflow_definitions
}

module "task_batch_compute" {
  source = "./task-batch-compute"
  for_each = {
    for compute in module.typed_definitions.cirrus_task_batch_compute :
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
    for task in module.typed_definitions.cirrus_tasks :
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
    for workflow in module.typed_definitions.cirrus_workflows :
    workflow.name => workflow
  }

  cirrus_prefix   = local.cirrus_prefix
  cirrus_tasks    = module.task
  workflow_config = each.value
}