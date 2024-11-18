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

variable "additional_lambdas" {
  description = "Map of lambda name (without cirrus prefix) to lambda detailed configuration"
  type = map(
    object({
      description     = string,
      ecr_image_uri   = optional(string, null),
      s3_bucket       = optional(string, null),
      s3_key          = optional(string, null),
      handler         = string,
      memory_mb       = optional(number, 128),
      timeout_seconds = optional(number, 10),
      runtime         = string,
      publish         = optional(bool, true),
      architectures   = optional(list(string), ["x86_64"]),
      env_vars        = optional(map(string), {}),
      vpc_enabled     = optional(bool, true)
    })
  )
  default = {}
}

variable "additional_lambda_roles" {
  description = "Map of lambda name (without cirrus prefix) to custom lambda role policy json"
  type        = map(string)
  default     = {}
}

variable "additional_warning_alarms" {
  description = "Map of lambda name (without cirrus prefix) to warning alarm configuration"
  type = map(
    object({
      evaluation_periods = optional(number, 5),
      period             = optional(number, 60),
      threshold          = optional(number, 10),
    })
  )
  default = {}
}

variable "additional_error_alarms" {
  description = "Map of lambda name (without cirrus prefix) to error alarm configuration"
  type = map(
    object({
      evaluation_periods = optional(number, 5),
      period             = optional(number, 60),
      threshold          = optional(number, 100),
    })
  )
  default = {}
}

variable "cirrus_tasks_batch_compute" {
  description = "Optional list of config objects each defining a single Cirrus Task Batch Compute resource set"
  type = list(object({
    name                                    = string
    batch_compute_environment_existing_name = optional(string)
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
      var.cirrus_tasks_batch_compute != null
      ? length(var.cirrus_tasks_batch_compute) == length(distinct(var.cirrus_tasks_batch_compute[*].name))
      : true
    )
    error_message = "Each cirrus_tasks_batch_compute object name must be unique to avoid resource clobbering"
  }

  validation {
    condition = (
      var.cirrus_tasks_batch_compute != null
      ? alltrue([
        for name in var.cirrus_tasks_batch_compute[*].name :
        length(regexall("^[A-Za-z0-9-]+$", name)) > 0 ? true : false
      ])
      : true
    )
    error_message = "Each cirrus_tasks_batch_compute object name must only use alphanumeric characters and hyphens"
  }
}

variable "cirrus_tasks" {
  description = "Optional list of configuration blocks each defining a single Cirrus Task"
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
      tasks_batch_compute_name = string
      container_properties     = string
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
  description = "Optional list of configuration objects each defining a single Cirrus Workflow"
  type = list(object({
    name                   = string
    template               = string
    non_cirrus_lambda_arns = optional(list(string))
    variables = optional(map(object({
      task_name = string
      task_type = string
      task_attr = string
    })))
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