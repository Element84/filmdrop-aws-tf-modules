variable "environment" {
  description = "Project environment"
  type        = string
  validation {
    condition     = length(var.environment) <= 7
    error_message = "The environment value must be 7 or fewer characters."
  }
}

variable "project_name" {
  description = "Project Name"
  type        = string
  validation {
    condition     = length(var.project_name) <= 8
    error_message = "The project_name value must be a 8 or fewer characters."
  }
}

variable "cirrus_process_sqs_timeout" {
  description = "Cirrus Process SQS Visibility Timeout"
  type        = number
  default     = 180
}

variable "cirrus_process_sqs_max_receive_count" {
  description = "Cirrus Process SQS Max Receive Count"
  type        = number
  default     = 5
}

variable "cirrus_timestream_magnetic_store_retention_period_in_days" {
  description = "Cirrus Timestream duration for which data must be stored in the magnetic store"
  type        = number
  default     = 93
}

variable "cirrus_timestream_memory_store_retention_period_in_hours" {
  description = "Cirrus Timestream duration for which data must be stored in the memory store"
  type        = number
  default     = 24
}

variable "cirrus_data_bucket" {
  description = "Cirrus data bucket"
  type        = string
}

variable "cirrus_payload_bucket" {
  description = "Cirrus payload bucket"
  type        = string
}

variable "cirrus_log_level" {
  description = "Cirrus log level (DEBUG, INFO, WARNING, ERROR)"
  type        = string
  default     = "INFO"
}

variable "cirrus_api_lambda_timeout" {
  description = "Cirrus API lambda timeout (sec)"
  type        = number
  default     = 10
}

variable "cirrus_api_lambda_memory" {
  description = "Cirrus API lambda memory (MB)"
  type        = number
  default     = 128
}

variable "cirrus_process_lambda_timeout" {
  description = "Cirrus process lambda timeout (sec)"
  type        = number
  default     = 10
}

variable "cirrus_process_lambda_memory" {
  description = "Cirrus process lambda memory (MB)"
  type        = number
  default     = 128
}

variable "cirrus_process_lambda_reserved_concurrency" {
  description = "Cirrus process reserved concurrency"
  type        = number
  default     = 16
}

variable "cirrus_update_state_lambda_timeout" {
  description = "Cirrus update-state lambda timeout (sec)"
  type        = number
  default     = 15
}

variable "cirrus_update_state_lambda_memory" {
  description = "Cirrus update-state lambda memory (MB)"
  type        = number
  default     = 128
}

variable "cirrus_pre_batch_lambda_timeout" {
  description = "Cirrus pre-batch lambda timeout (sec)"
  type        = number
  default     = 15
}

variable "cirrus_pre_batch_lambda_memory" {
  description = "Cirrus pre-batch lambda memory (MB)"
  type        = number
  default     = 128
}

variable "cirrus_post_batch_lambda_timeout" {
  description = "Cirrus post-batch lambda timeout (sec)"
  type        = number
  default     = 15
}

variable "cirrus_post_batch_lambda_memory" {
  description = "Cirrus post-batch lambda memory (MB)"
  type        = number
  default     = 128
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

variable "deploy_alarms" {
  type        = bool
  default     = true
  description = "Deploy Cirrus Alarms stack"
}

variable "custom_cloudwatch_warning_alarms_map" {
  description = "Map with custom CloudWatch Warning Alarms"
  type        = map(any)
  default     = {}
}

variable "custom_cloudwatch_critical_alarms_map" {
  description = "Map with custom CloudWatch Critical Alarms"
  type        = map(any)
  default     = {}
}

variable "cirrus_task_batch_compute" {
  description = <<-DESCRIPTION
    (optional, list[objects]) List of configuration objects that each define a
    single set of Cirrus Task batch compute resources. Each set may be used by
    zero..many batch Cirrus Tasks (see 'task' module).
    Object contents:
      - name: (required, string) Identifier for the Batch compute resources.
        Must be unique across all compute resource sets. Valid characters are:
        [A-Za-z0-9-]

      - batch_compute_environment_existing: (optional, object) Identifies an
        existing compute environment in the current AWS account. If specified,
        this module will use that CE instead of creating a new one. Useful if
        the argument subset exposed in the 'batch_compute_environment' variable
        is insufficient and/or you've deployed your own CE through other means.
        Contents:
          - name: (required, string) Name of the existing CE
          - is_fargate (required, bool): Whether the existing CE uses Fargate

      - batch_compute_environment: (optional, object) Used to create a compute
        environment with necessary ancillary resources. This exposes a minimal
        subset of the arguments available in the 'aws_batch_compute_environment'
        resource. Refer to that resource's documentation for more information:
        https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/batch_compute_environment
        Contents:
          - compute_resources: (required, object)
          - state: (optional, string)
          - type: (optional, string)
          - update_policy: (optional, object)

      - batch_job_queue_existing_name: (optional, object) Identifies an existing
        job queue in the current AWS account. If specified, this module will use
        that queue instead of creating a new one.
        Contents:
          - name: (required, string) Name of the existing job queue

      - batch_job_queue: (optional, object) Used to create a job queue with the
        necessary ancillary resources and automatic attachment to the target CE
        defined above. Only necessary if the job queue requires a fair share
        scheduling policy; if omitted, a default job queue will be created.
        Contents:
          - fair_share_policy: (optional, object) Used to create and attach an
            'aws_batch_scheduling_policy' resource to the job queue. Refer to
            that resource's documentation for more information:
            https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/batch_scheduling_policy

      - ec2_launch_template_existing: (optional, object) Identifies an existing
        launch template in the current AWS account. If specified, this module
        will use that template instead of creating a new one. Useful if the
        argument subset exposed in the 'ec2_launch_template' variable is
        insufficient and you've deployed your own template through other means.
        Contents:
          - name: (required, string) Name of the existing launch template

      - ec2_launch_template: (optional, object) Used to create a launch template
        with the necessary ancillary resources. This exposes a minimal subset of
        the arguments available in the 'aws_launch_template' resource. Refer to
        that resource's documentation for more information:
        https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template
        Contents:
          - user_data: (optional, string) Path to the user data start script.
            The path must be relative to the ROOT module of the Terraform
            deployment.
          - ebs_optimized: (optional, bool)
          - block_device_mappings: (optional, list[object])

    Prefer to configure the resources above through this module and not through
    the "existing" arguments wherever possible; this ensures consistent resource
    configuration and behavior across the Cirrus deployment.
  DESCRIPTION

  type = list(object({
    name = string

    batch_compute_environment_existing = optional(object({
      name       = string
      is_fargate = bool
    }))
    batch_compute_environment = optional(object({
      compute_resources = object({
        max_vcpus           = number
        type                = string
        allocation_strategy = optional(string)
        bid_percentage      = optional(number)
        desired_vcpus       = optional(number)
        ec2_configuration = optional(object({
          image_id_override = optional(string)
          image_type        = optional(string)
        }))
        ec2_key_pair       = optional(string)
        instance_type      = optional(list(string))
        min_vcpus          = optional(number)
        placement_group    = optional(string)
        security_group_ids = optional(list(string))
        subnets            = optional(list(string))
      })
      state = optional(string)
      type  = optional(string)
      update_policy = optional(object({
        job_execution_timeout_minutes = number
        terminate_jobs_on_update      = bool
      }))
    }))
    batch_job_queue_existing = optional(object({
      name = string
    }))
    batch_job_queue = optional(object({
      fair_share_policy = optional(object({
        compute_reservation = optional(number)
        share_decay_seconds = optional(number)
        share_distributions = list(object({
          share_identifier = string
          weight_factor    = number
        }))
      }))
      state = optional(string)
    }))
    ec2_launch_template_existing = optional(object({
      name = string
    }))
    ec2_launch_template = optional(object({
      user_data     = optional(string)
      ebs_optimized = optional(bool)
      block_device_mappings = optional(list(object({
        device_name  = string
        no_device    = optional(bool)
        virtual_name = optional(string)
        ebs = optional(object({
          delete_on_termination = optional(bool)
          encrypted             = optional(bool)
          iops                  = optional(string)
          kms_key_id            = optional(string)
          snapshot_id           = optional(string)
          throughput            = optional(number)
          volume_size           = optional(number)
          volume_type           = optional(string)
        }))
      })))
    }))
  }))

  default  = []
  nullable = true

  validation {
    condition = (
      var.cirrus_task_batch_compute != null
      ? length(var.cirrus_task_batch_compute) == length(distinct(var.cirrus_task_batch_compute[*].name))
      : true
    )
    error_message = "Each cirrus_task_batch_compute object name must be unique to avoid resource clobbering"
  }

  validation {
    condition = (
      var.cirrus_task_batch_compute != null
      ? alltrue([
        for name in var.cirrus_task_batch_compute[*].name :
        length(regexall("^[A-Za-z0-9-]+$", name)) > 0 ? true : false
      ])
      : true
    )
    error_message = "Each cirrus_task_batch_compute object name must only use alphanumeric characters and hyphens"
  }
}

variable "cirrus_tasks" {
  description = <<-DESCRIPTION
    (optional, list[objects]) List of configuration objects that each define a
    single Cirrus Task. Each Task may used by zero..many Cirrus Workflows (see
    'workflow' module). A Task may have a Lambda config, Batch config, or both.
    Object contents:
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

  type = list(object({
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
      s3_bucket       = optional(string)
      s3_key          = optional(string)
      handler         = optional(string)
      runtime         = optional(string)
      timeout_seconds = optional(number)
      memory_mb       = optional(number)
      publish         = optional(bool)
      architectures   = optional(list(string))
      env_vars        = optional(map(string))
      vpc_enabled     = optional(bool)
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
  }))

  default  = []
  nullable = true

  validation {
    condition = (
      var.cirrus_tasks != null
      ? length(var.cirrus_tasks) == length(distinct(var.cirrus_tasks[*].name))
      : true
    )
    error_message = "Each cirrus_tasks object name must be unique to avoid resource clobbering"
  }

  validation {
    condition = (
      var.cirrus_tasks != null
      ? alltrue([
        for name in var.cirrus_tasks[*].name :
        length(regexall("^[A-Za-z0-9-]+$", name)) > 0 ? true : false
      ])
      : true
    )
    error_message = "Each cirrus_tasks object name must only use alphanumeric characters and hyphens"
  }
}

variable "cirrus_workflows" {
  description = <<-DESCRIPTION
    (optional, list[objects]) List of configuration objects that each define a
    single Cirrus Workflow.
    Object contents:
      - name: (required, string) Identifier for the Cirrus Workflow. Must be
        unique across all Cirrus Workflows. Valid characters are: [A-Za-z0-9-]

      - non_cirrus_lambda_arns: (optional, list[string]) List of Lambda function
        ARNs that'll be executed by the Workflow but are not managed by a Cirrus
        task. This is necessary for granting the Workflow execution role invoke
        permissions on these functions.

      - default_template_config: (optional, object) Used to create an Amazon
        State Machine by rendering and combining predefined state configurations
        using outputs from the Cirrus Tasks referenced in 'state_sequence'. If
        your State Machine is a simple sequential execution of Cirrus Tasks,
        this config should be preferred over 'custom_template_config' as it
        removes the need for creating a State Machine definition template.
        Contents:
          - description: (required, string) Workflow description
          - allow_retry: (required, bool) Whether individual states should be
            retried in the event of a failure.
          - state_sequence: (required, list[object]) List of Cirrus Tasks that
            will be executed sequentially.
            Contents:
              - task_name: (required, string) Cirrus Task name. Used for getting
                Task output resource ARNs. Will also be used for the state name
                if 'state_name' is omitted.
              - task_type: (required, string) lambda or batch
              - state_name: (optional, string) State name. Must be unique within
                the Workflow. In most cases, this can be omitted as 'task_name'
                is used by default. Useful if you need to call the same Task
                multiple times within a Workflow.

      - custom_template_config: (optional, object) Used to create an Amazon
        State Machine by rendering a user-provided template with variables that
        reference Cirrus Task outputs. Useful for complex State Machines that
        cannot be created using the 'default_template_config' option.
        Contents:
          - filepath: (required, string) Path to an Amazon State Machine
            template definition. The path must be relative to the ROOT module of
            the Terraform deployment. The template should use valid Amazon State
            Language syntax; wherever a Cirrus Task resource ARN is needed, a
            Terraform interpolation sequence (a "$\{...}" without the "\") may
            be used instead. The variable name does not matter so long as there
            is a corresponding entry in the "template_variables" argument.
            Example template snippet:

              "States": {
                "FirstState": {
                  "Type": "Task",
                  "Resource": "$\{my-task-lambda}",  // REMOVE THE "\"
                  "Next": "SecondState",
                  ...
                },

            Cirrus may deploy and manage several builtin tasks. Resource ARNs
            for these tasks may be referenced in a Workflow template using
            predefined variable names without having to supply a
            'template_variable' entry.
              - If Batch Tasks were created, these variables may be used:
                - PRE-BATCH: cirrus-geo pre-batch Lambda function ARN
                - POST-BATCH: cirrus-geo post-batch Lambda function ARN

          - template_variables: (optional, map[object]) Map of template variable
            names to their corresponding Cirrus Task attributes. Assuming a
            Cirrus Task named "my-task" with a Lambda config was passed to the
            'task' module, the following workflow template variable config:

              my-task-lambda = {
                task_name = "my-task"
                task_type = "lambda"
                task_attr = "function_arn"
              }

            when used with the example Workflow snippet above, would result in
            the following content after template interpolation:

              "States": {
                "FirstState": {
                  "Type": "Task",
                  "Resource": "arn:aws:lambda:us-west-2:123456789012:function:my-function",
                  "Next": "SecondState",
                  ...
                },
  DESCRIPTION

  type = list(object({
    name                   = string
    non_cirrus_lambda_arns = optional(list(string))
    default_template_config = optional(object({
      description = string
      allow_retry = bool
      state_sequence = list(object({
        state_name = optional(string)
        task_name  = string
        task_type  = string
      }))
    }))
    custom_template_config = optional(object({
      filepath = string
      variables = optional(map(object({
        task_name = string
        task_type = string
        task_attr = string
      })))
    }))
  }))

  default  = []
  nullable = true

  validation {
    condition = (
      var.cirrus_workflows != null
      ? length(var.cirrus_workflows) == length(distinct(var.cirrus_workflows[*].name))
      : true
    )
    error_message = "Each cirrus_workflows object name must be unique to avoid resource clobbering"
  }

  validation {
    condition = (
      var.cirrus_workflows != null
      ? alltrue([
        for name in var.cirrus_workflows[*].name :
        length(regexall("^[A-Za-z0-9-]+$", name)) > 0 ? true : false
      ])
      : true
    )
    error_message = "Each cirrus_workflows object name must only use alphanumeric characters and hyphens"
  }
}