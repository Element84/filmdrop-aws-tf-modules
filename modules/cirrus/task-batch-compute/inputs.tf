variable "cirrus_prefix" {
  description = "Prefix for Cirrus-managed resources"
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

variable "batch_compute_config" {
  description = "Configuration block defining a single Cirrus Task Batch Compute resource set"
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
  })

  # Value must be provided else this module serves no purpose
  nullable = false
}