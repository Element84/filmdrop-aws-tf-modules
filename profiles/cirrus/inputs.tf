variable "environment" {
  description = "Project environment."
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

variable "private_subnet_ids" {
  description = "List of private subnet ids in the FilmDrop vpc"
  type        = list(string)
}

variable "security_group_id" {
  description = "Default security groups in the FilmDrop vpc"
  type        = string
}

variable "cirrus_inputs" {
  description = "Inputs for FilmDrop Cirrus deployment"
  type = object({
    data_bucket    = string
    payload_bucket = string
    log_level      = string
    deploy_alarms  = bool
    custom_alarms = object({
      warning  = map(any)
      critical = map(any)
    })
    process = object({
      sqs_timeout           = number
      sqs_max_receive_count = number
    })
    state = object({
      timestream_magnetic_store_retention_period_in_days = number
      timestream_memory_store_retention_period_in_hours  = number
    })
    api_lambda = object({
      timeout = number
      memory  = number
    })
    process_lambda = object({
      timeout              = number
      memory               = number
      reserved_concurrency = number
    })
    update_state_lambda = object({
      timeout = number
      memory  = number
    })
    pre_batch_lambda = object({
      timeout = number
      memory  = number
    })
    post_batch_lambda = object({
      timeout = number
      memory  = number
    })
    task_batch_compute = optional(list(object({
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
    })))
    tasks = optional(list(object({
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
    })))
    workflows = optional(list(object({
      name                   = string
      template               = string
      non_cirrus_lambda_arns = optional(list(string))
      template_variables = optional(map(object({
        task_name = string
        task_type = string
        task_attr = string
      })))
    })))
  })
  default = {
    data_bucket    = "cirrus-data-bucket-name"
    payload_bucket = "cirrus-payload-bucket-name"
    log_level      = "INFO"
    deploy_alarms  = true
    custom_alarms = {
      warning  = {}
      critical = {}
    }
    process = {
      sqs_timeout           = 180
      sqs_max_receive_count = 5
    }
    state = {
      timestream_magnetic_store_retention_period_in_days = 93
      timestream_memory_store_retention_period_in_hours  = 24
    }
    api_lambda = {
      timeout = 10
      memory  = 128
    }
    process_lambda = {
      timeout              = 10
      memory               = 128
      reserved_concurrency = 16
    }
    update_state_lambda = {
      timeout = 15
      memory  = 128
    }
    pre_batch_lambda = {
      timeout = 15
      memory  = 128
    }
    post_batch_lambda = {
      timeout = 15
      memory  = 128
    }
    task_batch_compute = []
    tasks              = []
    workflows          = []
  }
}

variable "warning_sns_topic_arn" {
  description = "String with FilmDrop Warning SNS topic ARN"
  type        = string
}

variable "critical_sns_topic_arn" {
  description = "String with FilmDrop Critical SNS topic ARN"
  type        = string
}
