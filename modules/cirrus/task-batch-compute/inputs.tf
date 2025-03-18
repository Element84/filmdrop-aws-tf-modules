variable "resource_prefix" {
  description = "String prefix to be used in every named resource."
  type        = string
  nullable    = false
}

variable "vpc_subnet_ids" {
  description = "List of subnet ids in the target VPC that cirrus task batch compute resources should be connected to."
  type        = list(string)
  nullable    = false
}

variable "vpc_security_group_ids" {
  description = "List of security groups in the target VPC that cirrus task batch compute resources should use."
  type        = list(string)
  nullable    = false
}

variable "batch_compute_config" {
  # NOTE: type changes here require changes in the typed-definitions module, too
  description = <<-DESCRIPTION
  Defines a single set of cirrus task batch compute resources. This set may be used by zero..many batch cirrus tasks (see `task` module).

  `name`: Identifier for the cirrus batch compute resources. Must be unique across all cirrus compute resource sets. Valid characters are: `[A-Za-z0-9-]`.

  `batch_compute_environment_existing`: Identifies an existing compute environment in the current AWS account. If specified, this module will use that CE instead of creating a new one. Useful if the argument subset exposed in the `batch_compute_config.batch_compute_environment` variable is insufficient and/or you've deployed your own CE through other means. Object contents:
  - `batch_compute_environment_existing.name`: Name of the existing CE.
  - `batch_compute_environment_existing.is_fargate`: Whether the existing CE uses Fargate.

  `batch_compute_environment`: Used to create a compute environment with necessary ancillary resources. This exposes a minimal subset of the arguments available in the `aws_batch_compute_environment` resource. Refer to that resource's [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/batch_compute_environment) for more information on the available arguments. Object contents:
  - `batch_compute_environment.compute_resources`
  - `batch_compute_environment.state`
  - `batch_compute_environment.type`
  - `batch_compute_environment.update_policy`

  `batch_job_queue_existing`: Identifies an existing job queue in the current AWS account. If specified, this module will use that queue instead of creating a new one. Object contents:
  - `batch_job_queue_existing.name`: Name of the existing job queue.

  `batch_job_queue`: Used to create a job queue with the necessary ancillary resources and automatic attachment to the target CE defined above. Only necessary if the job queue requires a fair share scheduling policy; if omitted, a default job queue will be created. Object contents:
  - `batch_job_queue.fair_share_policy`: Used to create and attach an `aws_batch_scheduling_policy` resource to the job queue. Refer to that resource's [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/batch_scheduling_policy) for more information on the available arguments. To utilize any defined share identifiers, you will need to add `ShareIdentifer` with the applicable value under `Parameters` in a cirrus workflow state machine definition.

  `ec2_launch_template_existing`: Identifies an existing launch template in the current AWS account. If specified, this module will use that template instead of creating a new one. Useful if the argument subset exposed in the `batch_compute_config.ec2_launch_template` variable is insufficient and you've deployed your own template through other means. Object contents:
  - `ec2_launch_template_existing.name`: Name of the existing launch template.

  `ec2_launch_template`:  Used to create a launch template with the necessary ancillary resources. This exposes a minimal subset of the arguments available in the `aws_launch_template` resource. Refer to that resource's [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) for more information on the available arguments. Object contents:
  - `ec2_launch_template.user_data`
  - `ec2_launch_template.ebs_optimized`
  - `ec2_launch_template.block_device_mappings`

  Prefer to configure the resources above through this module and not through the `_existing` arguments wherever possible; this ensures consistent resource configuration and behavior across the Cirrus deployment.
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  DESCRIPTION

  type = object({
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
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  })
  # The `~~~~` comment above is to ensure the markdown table column generated
  # by terraform-docs is wide enough for the object schema to be readable.

  # Value must be provided else this module serves no purpose
  nullable = false

  validation {
    condition = (
      var.batch_compute_config.batch_compute_environment_existing != null
      || var.batch_compute_config.batch_compute_environment != null
    )
    error_message = <<-ERROR
      Task Batch Compute inputs must provide 'batch_compute_environment' or
      'batch_compute_environment_existing' configuration objects.
    ERROR
  }
}
