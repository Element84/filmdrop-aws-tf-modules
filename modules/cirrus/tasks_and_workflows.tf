# RESOLVE DEFINITION VARIABLES FROM SSM
# ------------------------------------------------------------------------------
# SSM-sourced template variables must be resolved prior to definition templating
# ------------------------------------------------------------------------------
locals {
  # Flatten the nested SSM task mappings in prep for data source lookups.
  # Each leaf in these maps should be an SSM parameter path; flattening them
  # makes looping over the values easier.
  flattened_task_batch_compute_defs_vars_ssm = merge([
    for tbc_name, params in var.cirrus_task_batch_compute_definitions_variables_ssm : {
      for param_key, param_path in params :
      "${tbc_name}.${param_key}" => param_path
    }
  ]...)
  flattened_task_defs_vars_ssm = merge([
    for task_name, params in var.cirrus_task_definitions_variables_ssm : {
      for param_key, param_path in params :
      "${task_name}.${param_key}" => param_path
    }
  ]...)
  flattened_workflow_defs_vars_ssm = merge([
    for workflow_name, params in var.cirrus_workflow_definitions_variables_ssm : {
      for param_key, param_path in params :
      "${workflow_name}.${param_key}" => param_path
    }
  ]...)
}

# Query for the SSM parameter values.
# These are resolved at both plan and apply time, so there should be no issues
# with deferred resolution of templated definitions.
data "aws_ssm_parameter" "cirrus_task_batch_compute_definitions_variables_ssm" {
  for_each = local.flattened_task_batch_compute_defs_vars_ssm
  name     = each.value
}
data "aws_ssm_parameter" "cirrus_task_definitions_variables_ssm" {
  for_each = local.flattened_task_defs_vars_ssm
  name     = each.value
}
data "aws_ssm_parameter" "cirrus_workflow_definitions_variables_ssm" {
  for_each = local.flattened_workflow_defs_vars_ssm
  name     = each.value
}

locals {
  # Convert flattened map of SSM parameters back to nested structure.
  # The SSM path values are now resolved to what the parameter's value is/was.
  # Example:
  # Input:  {"my-compute.my_var" = "/cirrus/task-batch-compute/my-compute/parameter-for-my-var"}
  # Output: {"my-compute" = {"my_var" = "something"}} (where "something" is the SSM parameter value)
  cirrus_task_batch_compute_defs_vars_ssm_resolved = {
    for tbc_name, params in var.cirrus_task_batch_compute_definitions_variables_ssm :
    tbc_name => {
      for param_key, param_path in params :
      param_key => data.aws_ssm_parameter.cirrus_task_batch_compute_definitions_variables_ssm["${tbc_name}.${param_key}"].insecure_value
    }
  }

  # Get names of all definitions with template variables (both static and SSM)
  all_task_batch_compute_names_with_vars = toset(concat(
    keys(var.cirrus_task_batch_compute_definitions_variables),
    keys(local.cirrus_task_batch_compute_defs_vars_ssm_resolved)
  ))

  # Deep merge static and SSM variables in prep for templating.
  # SSM values take precedence (but duplicate keys should be avoided anyway).
  # Example:
  # static:  {"my-compute" = {"my_hardcoded_var" = "1234"}}
  # SSM:     {"my-compute" = {"my_var" = "something"}}
  # Result:  {"my-compute" = {"my_hardcoded_var" = "1234", "my_var" = "something"}}
  all_task_batch_compute_defs_vars = {
    for tbc_name in local.all_task_batch_compute_names_with_vars :
    tbc_name => merge(
      lookup(var.cirrus_task_batch_compute_definitions_variables, tbc_name, {}),
      lookup(local.cirrus_task_batch_compute_defs_vars_ssm_resolved, tbc_name, {})
    )
  }

  # Now do the same for task definitions
  cirrus_task_defs_vars_ssm_resolved = {
    for task_name, params in var.cirrus_task_definitions_variables_ssm :
    task_name => {
      for param_key, param_path in params :
      param_key => data.aws_ssm_parameter.cirrus_task_definitions_variables_ssm["${task_name}.${param_key}"].insecure_value
    }
  }
  all_task_names_with_vars = toset(concat(
    keys(var.cirrus_task_definitions_variables),
    keys(local.cirrus_task_defs_vars_ssm_resolved)
  ))
  all_task_defs_vars = {
    for task_name in local.all_task_names_with_vars :
    task_name => merge(
      lookup(var.cirrus_task_definitions_variables, task_name, {}),
      lookup(local.cirrus_task_defs_vars_ssm_resolved, task_name, {})
    )
  }

  # Now do the same for workflow definitions
  cirrus_workflow_defs_vars_ssm_resolved = {
    for workflow_name, params in var.cirrus_workflow_definitions_variables_ssm :
    workflow_name => {
      for param_key, param_path in params :
      param_key => data.aws_ssm_parameter.cirrus_workflow_definitions_variables_ssm["${workflow_name}.${param_key}"].insecure_value
    }
  }
  all_workflow_names_with_vars = toset(concat(
    keys(var.cirrus_workflow_definitions_variables),
    keys(local.cirrus_workflow_defs_vars_ssm_resolved)
  ))
  all_workflow_defs_vars = {
    for workflow_name in local.all_workflow_names_with_vars :
    workflow_name => merge(
      lookup(var.cirrus_workflow_definitions_variables, workflow_name, {}),
      lookup(local.cirrus_workflow_defs_vars_ssm_resolved, workflow_name, {})
    )
  }
}
# ==============================================================================


# RENDER AND TYPECAST ALL DEFINITION TEMPLATES INTO HCL
# ------------------------------------------------------------------------------
locals {
  # These variables may be used in definition templates for convenience.
  builtin_definitions_variables = {
    CIRRUS_DATA_BUCKET    = module.base.cirrus_data_bucket
    CIRRUS_PAYLOAD_BUCKET = module.base.cirrus_payload_bucket
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
      yamldecode(templatefile(tbc_yaml, merge(
        local.all_task_batch_compute_defs_vars,
        local.builtin_definitions_variables
      )))
    ] : null
  )
  cirrus_task_definitions = (
    var.cirrus_task_definitions_dir != null ? [
      for task_yaml in fileset(path.root, "${var.cirrus_task_definitions_dir}/**/definition.yaml") :
      yamldecode(templatefile(task_yaml, merge(
        local.all_task_defs_vars,
        local.builtin_definitions_variables
      )))
    ] : null
  )
  cirrus_workflow_definitions = (
    var.cirrus_workflow_definitions_dir != null ? [
      for workflow_yaml in fileset(path.root, "${var.cirrus_workflow_definitions_dir}/**/definition.yaml") :
      yamldecode(templatefile(workflow_yaml, merge(
        local.all_workflow_defs_vars,
        local.builtin_definitions_variables
      )))
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
# ==============================================================================


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
  workflow_definitions_variables         = local.all_workflow_defs_vars
  builtin_workflow_definitions_variables = local.builtin_definitions_variables
}
# ==============================================================================
