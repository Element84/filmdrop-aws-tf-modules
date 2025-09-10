variable "resource_prefix" {
  description = "String prefix to be used in every named resource."
  type        = string
  nullable    = false
}

variable "vpc_subnet_ids" {
  description = "List of subnet ids in the target VPC that cirrus task resources should be connected to."
  type        = list(string)
  nullable    = false
}

variable "vpc_security_group_ids" {
  description = "List of security groups in the target VPC that cirrus task resources should use."
  type        = list(string)
  nullable    = false
}

variable "task_config" {
  # NOTE: type changes here require changes in the typed-definitions module, too
  description = <<-DESCRIPTION
  Defines a single cirrus task. This task may be used by zero..many cirrus workflows (see `workflow` module). A task may have a lambda config, a batch config, or both.

  `name`: Identifier for the cirrus task. Must be unique across all cirrus tasks. Valid characters are: `[A-Za-z0-9-]`.

  `common_role_statements`: List of IAM statements to be applied to both the lambda function and the batch job IAM role. This object is used to create a `aws_iam_policy_document` terraform data source. Refer to that data source's [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) for more information on the available arguments.

  `lambda`: Used to create a task lambda function and its ancillary resources. Many of the available arguments map directly to the ones in the `aws_lambda_function` terraform resource. Refer to that resource's [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) for more information on the available arguments. Object contents:
  - `lambda.resolve_ecr_tag_to_digest`: Whether the image in `lambda.ecr_image_uri` should have its tag resolved to the latest digest. Useful for tasks that use mutable image tags. Only valid for ECR-based images. Image URI must be in `<ECR repository URI>@<tag>` format.
  - `lambda.vpc_enabled`: Whether the lambda should be deployed within the specified `var.vpc_subnet_ids` and use `var.vpc_security_group_ids`.
  - `lambda.role_statements`: List of IAM statements to be applied to the lambda execution role in addition to any specified in `var.task_config.common_role_statements`.
  - `lambda.alarms`: List of CloudWatch alarm configs that will be created to monitor the cirrus task lambda function.
  - ... other common [aws_lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function#argument-reference) arguments ...

  `batch`: Used to create a task batch job definition and its ancillary resources. Many of the available arguments map directly to the ones in the `aws_batch_job_definition` resource. Refer to that resource's [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/batch_job_definition) for more information on the available arguments. Object contents:
  - `batch.task_batch_compute_name`: The name of a batch compute resource set created by the `task_batch_compute` module. This determines where invocations of this task's job definition will run.
  - `batch.container_properties`: JSON string used for registering the batch job. See the [RegisterJobDefinition AWS documentation](https://docs.aws.amazon.com/batch/latest/APIReference/API_RegisterJobDefinition.html) for valid key/values.
  - `batch.resolve_ecr_tag_to_digest`: Whether the image in `batch.container_properties.image` should have its tag resolved to the latest digest. Useful for tasks that use mutable image tags. Only valid for ECR-based images. Image URI must be in `<ECR repository URI>@<tag>` format.
  - `batch.retry_strategy`: Configures how failed batch jobs should be retried, if at all.
  - `batch.parameters`: Parameter substitution placeholders that can be overridden at batch job submission time. For typical cirrus batch tasks, the values `url` and `url_out` should be set to any non-empty string value here.
  - `batch.role_statements`: List of IAM statements to be applied to the batch job execution role in addition to any specified in `var.task_config.common_role_statements`.
  - `batch.scheduling priority`: Determines the priority of these batch jobs in a job queue with a fair share scheduling policy. If the associated compute environment's queue does not use a fair share policy, this should not be set.
  - `batch.timeout_seconds`: Maximum duration these batch jobs should be allowed to run before being terminated by AWS.
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  DESCRIPTION

  type = object({
    name = string

    common_role_statements = optional(list(object({
      sid           = string
      effect        = string
      actions       = list(string)
      resources     = list(string)
      not_actions   = optional(list(string))
      not_resources = optional(list(string))
      condition = optional(object({
        test     = string
        variable = string
        values   = list(string)
      }))
      principals = optional(object({
        type        = string
        identifiers = list(string)
      }))
      not_principals = optional(object({
        type        = string
        identifiers = list(string)
      }))
    })))

    lambda = optional(object({
      description               = optional(string)
      ecr_image_uri             = optional(string)
      resolve_ecr_tag_to_digest = optional(bool)
      filename                  = optional(string)
      image_config = optional(object({
        command           = optional(list(string))
        entry_point       = optional(list(string))
        working_directory = optional(string)
      }))
      s3_bucket            = optional(string)
      s3_key               = optional(string)
      handler              = optional(string)
      runtime              = optional(string)
      timeout_seconds      = optional(number)
      memory_mb            = optional(number)
      ephemeral_storage_mb = optional(number)
      publish              = optional(bool)
      architectures        = optional(list(string))
      env_vars             = optional(map(string))
      vpc_enabled          = optional(bool)
      role_statements = optional(list(object({
        sid           = string
        effect        = string
        actions       = list(string)
        resources     = list(string)
        not_actions   = optional(list(string))
        not_resources = optional(list(string))
        condition = optional(object({
          test     = string
          variable = string
          values   = list(string)
        }))
        principals = optional(object({
          type        = string
          identifiers = list(string)
        }))
        not_principals = optional(object({
          type        = string
          identifiers = list(string)
        }))
      })))
      alarms = optional(list(object({
        critical            = bool
        statistic           = string
        metric_name         = string
        comparison_operator = string
        threshold           = number
        period              = optional(number, 60)
        evaluation_periods  = optional(number, 5)
      })))
    }))

    batch = optional(object({
      task_batch_compute_name   = string
      container_properties      = string
      resolve_ecr_tag_to_digest = optional(bool)
      retry_strategy = optional(object({
        attempts = number
        evaluate_on_exit = optional(list(object({
          action           = string
          on_exit_code     = optional(string)
          on_reason        = optional(string)
          on_status_reason = optional(string)
        })))
      }))
      parameters = optional(map(string))
      role_statements = optional(list(object({
        sid           = string
        effect        = string
        actions       = list(string)
        resources     = list(string)
        not_actions   = optional(list(string))
        not_resources = optional(list(string))
        condition = optional(object({
          test     = string
          variable = string
          values   = list(string)
        }))
        principals = optional(object({
          type        = string
          identifiers = list(string)
        }))
        not_principals = optional(object({
          type        = string
          identifiers = list(string)
        }))
      })))
      scheduling_priority = optional(number)
      timeout_seconds     = optional(number)
    }))
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  })
  # The `~~~~` comment above is to ensure the markdown table column generated
  # by terraform-docs is wide enough for the object schema to be readable.

  # Value must be provided else this module serves no purpose
  nullable = false

  validation {
    condition     = var.task_config.batch != null || var.task_config.lambda != null
    error_message = "Tasks must specify Batch config, Lambda config, or both."
  }

  validation {
    condition = (
      try(var.task_config.batch.parameters, null) != null
      ? alltrue([
        for param_key, param_val in var.task_config.batch.parameters :
        param_val != ""
      ])
      : true
    )
    error_message = <<-ERROR
      Batch Job Definition 'parameters' key/val pairs must not have empty string
      values; doing so will result in Terraform creating new definition versions
      during every deploy. Use a filler value instead.
    ERROR
  }
}

variable "cirrus_task_batch_compute" {
  description = <<-DESCRIPTION
  (Optional) A map of `task_batch_compute` module outputs keyed by their resource set's `name`. These are used to link any batch cirrus tasks with a target compute resource set.
  DESCRIPTION

  type = map(object({
    batch = object({
      compute_environment_arn        = string
      compute_environment_is_fargate = bool
      ecs_task_execution_role_arn    = string
      job_queue_arn                  = string
      job_queue_is_fair_share        = string
    })
  }))

  # Value only required if the task has a Batch configuration
  nullable = true
  default  = null

  # Cross-variable validation is not available at this time; instead, a runtime
  # error will be raised if the user attempts to deploy a Batch task without
  # defining any Cirrus compute resources.
  # TODO - CVG - Terraform v1.9+ adds cross-variable validation. Need to update.
}

variable "cirrus_payload_bucket" {
  description = <<-DESCRIPTION
  (Optional) S3 bucket for storing cirrus payloads. Required if any cirrus batch tasks are defined as their job's IAM role will automatically be granted read/write permissions on this bucket to facilitate the necessary `pre-batch -> batch job -> post-batch` flow used by state machines.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}

variable "warning_sns_topic_arn" {
  description = <<-DESCRIPTION
  (Optional) SNS topic to be used by all cirrus lambda task `warning` alarms. This is primarily used by the `pre-batch` and `post-batch` lambda tasks that are managed by the parent `cirrus` module.

  If any non-critical cirrus lambda task alarms are configured via `var.task_config.lambda.alarms`, they will use this SNS topic for their alarm action.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}

variable "critical_sns_topic_arn" {
  description = <<-DESCRIPTION
  (Optional) SNS topic to be used by all cirrus lambda task `critical` alarms. This is primarily used by the `pre-batch` and `post-batch` lambda tasks that are managed by the parent `cirrus` module.

  If any critical cirrus lambda task alarms are configured via `var.task_config.lambda.alarms`, they will use this SNS topic for their alarm action.
  DESCRIPTION
  type        = string
  nullable    = true
  default     = null
}
