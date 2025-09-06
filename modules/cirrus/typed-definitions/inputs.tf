variable "cirrus_task_batch_compute" {
  description = <<-DESCRIPTION
  (Optional) List of objects that conform to the task-batch-compute module's
  "batch_compute_config" object schema. Used for explicitly typecasting the HCL
  objects that were constructed from YAML definition files.

  If null, an empty list is returned.
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

  # Force default if null
  nullable = false
  default  = []

  validation {
    condition     = length(var.cirrus_task_batch_compute) == length(distinct(var.cirrus_task_batch_compute[*].name))
    error_message = "Each cirrus task batch compute name must be unique to avoid resource clobbering"
  }

  validation {
    condition = alltrue([
      for name in var.cirrus_task_batch_compute[*].name :
      length(regexall("^[A-Za-z0-9-]+$", name)) > 0 ? true : false
    ])
    error_message = "Each cirrus task batch compute name must only use alphanumeric characters and hyphens"
  }
}

variable "cirrus_tasks" {
  description = <<-DESCRIPTION
  (Optional) List of objects that conform to the task module's "task_config"
  object schema. Used for explicitly typecasting the HCL objects that were
  constructed from YAML definition files.

  If null, an empty list is returned.
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
      description               = optional(string)
      ecr_image_uri             = optional(string)
      resolve_ecr_tag_to_digest = optional(bool)
      filename                  = optional(string)
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
  }))

  # Force default if null
  nullable = false
  default  = []

  validation {
    condition     = length(var.cirrus_tasks) == length(distinct(var.cirrus_tasks[*].name))
    error_message = "Each cirrus task name must be unique to avoid resource clobbering"
  }

  validation {
    condition = alltrue([
      for name in var.cirrus_tasks[*].name :
      length(regexall("^[A-Za-z0-9-]+$", name)) > 0 ? true : false
    ])
    error_message = "Each cirrus task name must only use alphanumeric characters and hyphens"
  }
}

variable "cirrus_workflows" {
  description = <<-DESCRIPTION
  (Optional) List of objects that conform to the workflow module's
  "workflow_config" object schema. Used for explicitly typecasting the HCL
  objects that were constructed from YAML definition files.

  If null, an empty list is returned.
  DESCRIPTION
  type = list(object({
    name                   = string
    state_machine_filepath = string
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
  }))

  # Force default if null
  nullable = false
  default  = []

  validation {
    condition     = length(var.cirrus_workflows) == length(distinct(var.cirrus_workflows[*].name))
    error_message = "Each cirrus workflow name must be unique to avoid resource clobbering"
  }

  validation {
    condition = alltrue([
      for name in var.cirrus_workflows[*].name :
      length(regexall("^[A-Za-z0-9-]+$", name)) > 0 ? true : false
    ])
    error_message = "Each cirrus workflow name must only use alphanumeric characters and hyphens"
  }
}
