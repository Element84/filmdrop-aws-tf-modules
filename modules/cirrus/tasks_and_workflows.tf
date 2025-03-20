locals {
  # These variables may be used in definition templates for convenience.
  builtin_definitions_variables = {
    CIRRUS_DATA_BUCKET = module.base.cirrus_data_bucket
  }

  # Construct Cirrus task-batch-compute, task, and workflow definitions.
  # These are loaded from YAML representations of each module's expected input
  # config HCL objects. This approach avoids having excessively long inline
  # config and promotes readability by enabling each item to be split into its
  # own file without environment-specific redundancy.
  #
  # The YAML definitions are templated prior to HCL conversion to allow setting
  # environment-specific values. Task YAML definitions may include the builtin
  # variables above.
  #
  # Ternary defaults must be 'null' rather than an empty list since Terraform is
  # unable to implicitly typecast the complex config objects into a single type,
  # which would result in a type mismatch since tuple(n items) != list().
  cirrus_task_batch_compute_definitions = (
    var.cirrus_task_batch_compute_definitions_dir != null ? [
      for tbc_yaml in fileset(path.root, "${var.cirrus_task_batch_compute_definitions_dir}/**/definition.yaml") :
      yamldecode(templatefile(tbc_yaml, merge(var.cirrus_task_batch_compute_definitions_variables, local.builtin_definitions_variables)))
    ] : null
  )
  cirrus_task_definitions = (
    var.cirrus_task_definitions_dir != null ? [
      for task_yaml in fileset(path.root, "${var.cirrus_task_definitions_dir}/**/definition.yaml") :
      yamldecode(templatefile(task_yaml, merge(var.cirrus_task_definitions_variables, local.builtin_definitions_variables)))
    ] : null
  )
  cirrus_workflow_definitions = (
    var.cirrus_workflow_definitions_dir != null ? [
      for workflow_yaml in fileset(path.root, "${var.cirrus_workflow_definitions_dir}/**/definition.yaml") :
      yamldecode(templatefile(workflow_yaml, merge(var.cirrus_workflow_definitions_variables, local.builtin_definitions_variables)))
    ] : null
  )

  # These builtin tasks are created outside of the cirrus task module.
  # This map is constructed to replicate the cirrus task module output such that
  # they can be referenced in a state machine JSON like any user-defined task.
  cirrus_builtin_tasks = {
    pre-batch = {
      lambda = { function_arn = module.builtin_functions.pre_batch_lambda_function_arn }
      batch  = {}
    }
    post-batch = {
      lambda = { function_arn = module.builtin_functions.post_batch_lambda_function_arn }
      batch  = {}
    }
  }
}

module "typed_definitions" {
  source = "./typed-definitions"

  # The definitions constructed from YAML files above are tuples. We need a list
  # of strictly-typed objects for variable-length module invocations below. This
  # module call simply typecasts the input definitions and outputs the results.
  # See that module's README for more information.
  cirrus_task_batch_compute = local.cirrus_task_batch_compute_definitions
  cirrus_tasks              = local.cirrus_task_definitions
  cirrus_workflows          = local.cirrus_workflow_definitions
}

# Creates 0..many sets of Batch-related resources for cirrus batch compute
module "task_batch_compute" {
  source = "./task-batch-compute"
  for_each = {
    for compute in module.typed_definitions.cirrus_task_batch_compute :
    compute.name => compute
  }

  resource_prefix        = var.resource_prefix
  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids
  batch_compute_config   = each.value
}

# Creates 0..many sets of Batch and/or Lambda resources for cirrus tasks
module "task" {
  source = "./task"
  for_each = {
    for task in module.typed_definitions.cirrus_tasks :
    task.name => task
  }

  resource_prefix           = var.resource_prefix
  cirrus_payload_bucket     = module.base.cirrus_payload_bucket
  vpc_subnet_ids            = var.vpc_subnet_ids
  vpc_security_group_ids    = var.vpc_security_group_ids
  warning_sns_topic_arn     = var.warning_sns_topic_arn
  critical_sns_topic_arn    = var.critical_sns_topic_arn
  cirrus_task_batch_compute = module.task_batch_compute
  task_config               = each.value
}

# Creates 0..many sets of AWS State Machine resources for cirrus workflows
module "workflow" {
  source = "./workflow"
  for_each = {
    for workflow in module.typed_definitions.cirrus_workflows :
    workflow.name => workflow
  }

  resource_prefix = var.resource_prefix
  workflow_config = each.value
  cirrus_tasks = merge(
    module.task,
    local.cirrus_builtin_tasks
  )

  # Pass user-defined and builtin variables for state machine JSON templating
  workflow_definitions_variables         = var.cirrus_workflow_definitions_variables
  builtin_workflow_definitions_variables = local.builtin_definitions_variables
}
