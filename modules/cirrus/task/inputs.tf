variable "resource_prefix" {
  description = "String prefix to be used in every named resource."
  type        = string
  nullable    = false
}

variable "cirrus_payload_bucket" {
  description = "Cirrus payload bucket"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "List of subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of security groups in the FilmDrop vpc"
  type        = list(string)
}

variable "warning_sns_topic_arn" {
  description = "String with FilmDrop Warning SNS topic ARN"
  type        = string
}

variable "critical_sns_topic_arn" {
  description = "String with FilmDrop Critical SNS topic ARN"
  type        = string
}

variable "cirrus_task_batch_compute" {
  description = <<-DESCRIPTION
  (optional, map[object]) A map of the 'task_batch_compute' module outputs.
  These are used to link Batch Cirrus tasks with a target compute resource set.
  This should be set in the parent module and not by user input.
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

  # Cross-variable validation is not available at this time; instead, a runtime
  # error will be raised if the user attempts to deploy a Batch task without
  # defining any Cirrus compute resources.
  # TODO - CVG - Terraform v1.9+ adds cross-variable validation. Need to update.
}

variable "task_config" {
  # NOTE: type changes here require changes in the typed-definitions module, too
  description = <<-DESCRIPTION
    (required, object) Defines a single Cirrus Task. This Task may be used by
    zero..many Cirrus Workflows (see 'workflow' module). A Task may have Lambda
    config, Batch config, or both.
    Contents:
      - name: (required, string) Identifier for the Cirrus Task. Must be unique
        across all Cirrus Tasks. Valid characters are: [A-Za-z0-9-]

      - common_role_statements: (optional, list[object]) List of IAM statements
        to be applied to both the Lambda function and the Batch Job. This object
        is used to create an 'aws_iam_policy_document' data source. Refer to the
        documentation for more information on the available arguments in an IAM
        statement block:
        https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document

      - lambda: (optional, object) Used to create a Lambda function and all its
        ancillary resources. Many of the available arguments map directly to the
        ones in the 'aws_lambda_function' resource. Refer to the documentation
        for more information on those arguments:
        https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
        Contents:
          - filename: (optional, str): Path to the local Lambda ZIP. The path
            must be relative to the ROOT module of the Terraform deployment.
          - vpc_enabled: (optional, bool) Whether the Lambda should be deployed
            within the FilmDrop VPC.
          - role_statements: (optional, list[object]) List of IAM statements to
            be applied to the Lambda execution role. Similar arguments to the
            'common_role_statements' variable above.
          - alarms: (optional, list[object]): List of CloudWatch alarm configs
            that will be created to monitor the resulting Lambda function.
          - ... subset of common 'aws_lambda_function' arguments ...

      - batch: (optional, object) Used to create a Batch Job Definition and all
        ancillary resources. Many of the available arguments map directly to the
        ones in the 'aws_batch_job_definition' resource. Refer to the
        documentation for more information on those arguments:
        https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/batch_job_definition
        Contents:
          - task_batch_compute_name: (required, string) The name of a batch
            compute resource set created by the 'task_batch_compute' module.
            This determines where invocations of this Job definition will run.
          - role_statements: (optional, list[object]) List of IAM statements to
            be applied to the Batch Job / ECS Task execution role. Similar
            arguments to the 'common_role_statements' variable above.
          - ... subset of common 'aws_batch_job_definition' arguments ...
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
      description   = optional(string)
      ecr_image_uri = optional(string)
      filename      = optional(string)
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
      task_batch_compute_name = string
      container_properties    = string
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
  })

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
