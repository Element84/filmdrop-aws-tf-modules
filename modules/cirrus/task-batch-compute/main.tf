data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Save as locals to avoid obnoxiously long lines
  current_account = data.aws_caller_identity.current.account_id
  current_region  = data.aws_region.current.name

  # Only create if an existing compute environment config was not provided
  create_compute_environment = (
    try(var.batch_compute_config.batch_compute_environment_existing, null) == null
  )

  # Fargate-managed environments require special handling.
  # This boolean is used only for conditional resource creation and configuring
  # Fargate-related resource attributes that the user does NOT control; the user
  # is responsible for ensuring their config variable inputs are compatible with
  # their desired compute environment type (e.g., don't supply 'instance_type'
  # if using Fargate). Any such validation errors would be raised naturally by
  # Terraform at plan/apply time.
  new_compute_environment_is_fargate = (
    local.create_compute_environment
    ? startswith(var.batch_compute_config.batch_compute_environment.compute_resources.type, "FARGATE")
    : false
  )

  # Spot-type environments require special handling
  new_compute_environment_is_spot = (
    local.create_compute_environment
    ? endswith(var.batch_compute_config.batch_compute_environment.compute_resources.type, "SPOT")
    : false
  )

  # Only create if a non-Fargate compute environment will be created
  create_instance_profile = (
    local.create_compute_environment
    && (!local.new_compute_environment_is_fargate)
  )

  # Only create if a Fargate compute environment will be created
  create_ecs_execution_role = (
    local.create_compute_environment
    && local.new_compute_environment_is_fargate
  )

  # Only create if a non-Fargate Spot compute environment will be created
  create_spot_fleet_role = (
    local.create_compute_environment
    && local.new_compute_environment_is_spot
    && (!local.new_compute_environment_is_fargate)
  )

  # Only create if a non-Fargate compute environment will be created and the
  # user provided a launch template configuration and not an existing name
  create_launch_template = (
    local.create_compute_environment
    && (!local.new_compute_environment_is_fargate)
    && var.batch_compute_config.ec2_launch_template_existing == null
    && var.batch_compute_config.ec2_launch_template != null
  )

  # Only get if a non-Fargate compute environment will be created and the user
  # provided an existing launch template name. This is not the same as a simple
  # negation of 'create_launch_template' as the launch template (whether new or
  # existing) is not required by batch.
  get_launch_template = (
    local.create_compute_environment
    && (!local.new_compute_environment_is_fargate)
    && var.batch_compute_config.ec2_launch_template_existing != null
  )

  # Only create if an existing job queue name was not provided
  create_job_queue = (
    var.batch_compute_config.batch_job_queue_existing == null
  )

  # Only create if a job queue will be created and the user provided a batch
  # fair share scheduling policy.
  create_fair_share_policy = (
    local.create_job_queue
    && try(var.batch_compute_config.batch_job_queue.fair_share_policy, null) != null
  )
}


# IAM -- EC2 INSTANCE PROFILE
# ------------------------------------------------------------------------------
# Optionally create the role for instances deployed in the compute environment.
# It is only necessary for non-Fargate compute environments.
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "task_ec2_assume_role" {
  count = local.create_instance_profile ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    # Conditions to prevent the "confused deputy" security problem.
    # The "aws:SourceArn" can't be strictly defined as the Batch-managed EC2
    # instances will have unique IDs.
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ec2:${local.current_region}:${local.current_account}:instance/*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.current_account]
    }
  }
}

resource "aws_iam_role" "task_ec2" {
  count = local.create_instance_profile ? 1 : 0

  name_prefix        = "${var.resource_prefix}-compute-role-"
  description        = "EC2 instance role for Cirrus Task Compute '${var.batch_compute_config.name}'"
  assume_role_policy = data.aws_iam_policy_document.task_ec2_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "aws_managed_ecs_for_ec2" {
  count = local.create_instance_profile ? 1 : 0

  role       = aws_iam_role.task_ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "task_ec2" {
  count = local.create_instance_profile ? 1 : 0

  name_prefix = "${var.resource_prefix}-compute-role-"
  role        = aws_iam_role.task_ec2[0].name
}
# ==============================================================================


# IAM -- ECS TASK EXECUTION ROLE
# ------------------------------------------------------------------------------
# Create the role used by Fargate Agents for managing ECS task execution.
# It is only necessary for Fargate compute environments.
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "task_ecs_assume_role" {
  count = local.create_ecs_execution_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    # Conditions to prevent the "confused deputy" security problem
    # The "aws:SourceArn" can't be strictly defined as ECS clusters do not
    # currently support it.
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ecs:${local.current_region}:${local.current_account}:*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.current_account]
    }
  }
}

resource "aws_iam_role" "task_ecs" {
  count = local.create_ecs_execution_role ? 1 : 0

  name_prefix        = "${var.resource_prefix}-compute-role-"
  assume_role_policy = data.aws_iam_policy_document.task_ecs_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "aws_managed_ecs_task_execution" {
  count = local.create_ecs_execution_role ? 1 : 0

  role       = aws_iam_role.task_ecs[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# ==============================================================================


# IAM -- SPOT FLEET ROLE
# ------------------------------------------------------------------------------
# Optionally create the role for managing SPOT in the compute environment.
# It is only necessary for SPOT-type compute environments.
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "task_spot_fleet_assume_role" {
  count = local.create_spot_fleet_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["spotfleet.amazonaws.com"]
    }

    # Conditions to prevent the "confused deputy" security problem.
    # The "aws:SourceArn" can't be strictly defined as Spot Fleet request ARNs
    # have UUID suffixes.
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ec2:${local.current_region}:${local.current_account}:spot-fleet-request/sfr-*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.current_account]
    }
  }
}

resource "aws_iam_role" "task_spot_fleet" {
  count = local.create_spot_fleet_role ? 1 : 0

  name_prefix        = "${var.resource_prefix}-compute-role-"
  description        = "EC2 Spot Fleet role for Cirrus Task Compute '${var.batch_compute_config.name}'"
  assume_role_policy = data.aws_iam_policy_document.task_spot_fleet_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "aws_managed_spot_fleet_tagging" {
  count = local.create_spot_fleet_role ? 1 : 0

  role       = aws_iam_role.task_spot_fleet[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}
# ==============================================================================


# IAM -- BATCH SERVICE ROLE
# ------------------------------------------------------------------------------
# Optionally create the role for managing instances in the compute environment.
# It is needed for any compute environment deployed by this module.
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "task_batch_assume_role" {
  count = local.create_compute_environment ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["batch.amazonaws.com"]
    }

    # Conditions to prevent the "confused deputy" security problem.
    # The Batch compute environment "aws:SourceArn" can't be strictly defined as
    # they have randomly-generated suffixes added to their name.
    # The Batch job "aws:SourceArn" can't be strictly defined as they use UUIDs.
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:batch:${local.current_region}:${local.current_account}:compute-environment/*",
        "arn:aws:batch:${local.current_region}:${local.current_account}:job/*"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.current_account]
    }
  }
}

resource "aws_iam_role" "task_batch" {
  count = local.create_compute_environment ? 1 : 0

  name_prefix        = "${var.resource_prefix}-compute-role-"
  description        = "Batch service role for Cirrus Task Compute '${var.batch_compute_config.name}'"
  assume_role_policy = data.aws_iam_policy_document.task_batch_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "aws_managed_batch_service_role" {
  count = local.create_compute_environment ? 1 : 0

  role       = aws_iam_role.task_batch[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}
# ==============================================================================


# EC2 -- LAUNCH TEMPLATE
# ------------------------------------------------------------------------------
# Optionally create or retrieve a launch template for the compute environment.
# There are three possible scenarios:
#  - A launch template is retrieved from AWS
#  - A launch template is created by Terraform
#  - No launch template is used
#
# This launch template resource only exposes the most commonly used features.
# Much of the remaining configuration is often set and/or overwritten by the
# Batch compute environment that uses this template.
#
# If additional configuration options are needed, the user may create their own
# launch template outside of this module and pass the name of it via:
#   - var.batch_compute_config.ec2_launch_template_existing
# It will be retrieved as a data source to ensure it exists within the account.
#
# The launch template may be omitted by the user if not needed.
# It is not used for Fargate-managed environments and will not be created.
# ------------------------------------------------------------------------------
data "aws_launch_template" "task_batch" {
  count = local.get_launch_template ? 1 : 0

  name = var.batch_compute_config.ec2_launch_template_existing.name
}

resource "aws_launch_template" "task_batch" {
  count = local.create_launch_template ? 1 : 0

  name        = "${var.resource_prefix}-compute-${var.batch_compute_config.name}"
  description = "EC2 Launch Template for Cirrus Task Batch Compute item '${var.batch_compute_config.name}'"

  # Always update default to be the latest one managed by Terraform.
  # This removes the need for explicitly specifying versions elsewhere.
  update_default_version = true

  ebs_optimized = var.batch_compute_config.ec2_launch_template.ebs_optimized
  user_data = (
    var.batch_compute_config.ec2_launch_template.user_data != null
    ? filebase64("${path.root}/${var.batch_compute_config.ec2_launch_template.user_data}")
    : null
  )

  # Create zero to many block device mappings
  dynamic "block_device_mappings" {
    for_each = coalesce(var.batch_compute_config.ec2_launch_template.block_device_mappings, [])
    iterator = bdm

    content {
      device_name  = bdm.value.device_name
      no_device    = bdm.value.no_device
      virtual_name = bdm.value.virtual_name

      # Create zero or one EBS configuration blocks
      dynamic "ebs" {
        for_each = try(bdm.value.ebs, null) != null ? [bdm.value.ebs] : []
        iterator = ebs

        content {
          delete_on_termination = ebs.value.delete_on_termination
          encrypted             = ebs.value.encrypted
          iops                  = ebs.value.iops
          kms_key_id            = ebs.value.kms_key_id
          snapshot_id           = ebs.value.snapshot_id
          throughput            = ebs.value.throughput
          volume_size           = ebs.value.volume_size
          volume_type           = ebs.value.volume_type
        }
      }
    }
  }
}
# ==============================================================================


# BATCH -- COMPUTE ENVIRONMENT
# ------------------------------------------------------------------------------
# Either create or retrieve a compute environment.
# ------------------------------------------------------------------------------
data "aws_batch_compute_environment" "task_batch" {
  count = (!local.create_compute_environment) ? 1 : 0

  compute_environment_name = var.batch_compute_config.batch_compute_environment_existing.name
}

resource "aws_batch_compute_environment" "task_batch" {
  count = local.create_compute_environment ? 1 : 0

  compute_environment_name_prefix = "${var.resource_prefix}-task-compute-${var.batch_compute_config.name}-"
  service_role                    = aws_iam_role.task_batch[0].arn
  state                           = coalesce(var.batch_compute_config.batch_compute_environment.state, "ENABLED")
  type                            = coalesce(var.batch_compute_config.batch_compute_environment.type, "MANAGED")

  compute_resources {
    allocation_strategy = var.batch_compute_config.batch_compute_environment.compute_resources.allocation_strategy
    bid_percentage      = var.batch_compute_config.batch_compute_environment.compute_resources.bid_percentage
    desired_vcpus       = var.batch_compute_config.batch_compute_environment.compute_resources.desired_vcpus
    ec2_key_pair        = var.batch_compute_config.batch_compute_environment.compute_resources.ec2_key_pair
    instance_role       = local.create_instance_profile ? aws_iam_instance_profile.task_ec2[0].arn : null
    instance_type       = var.batch_compute_config.batch_compute_environment.compute_resources.instance_type
    max_vcpus           = var.batch_compute_config.batch_compute_environment.compute_resources.max_vcpus
    min_vcpus           = var.batch_compute_config.batch_compute_environment.compute_resources.min_vcpus
    placement_group     = var.batch_compute_config.batch_compute_environment.compute_resources.placement_group
    security_group_ids  = coalesce(var.batch_compute_config.batch_compute_environment.compute_resources.security_group_ids, var.vpc_security_group_ids)
    spot_iam_fleet_role = local.create_spot_fleet_role ? aws_iam_role.task_spot_fleet[0].arn : null
    subnets             = coalesce(var.batch_compute_config.batch_compute_environment.compute_resources.subnets, var.vpc_subnet_ids)
    type                = var.batch_compute_config.batch_compute_environment.compute_resources.type

    # Create zero or one EC2 configuration blocks
    dynamic "ec2_configuration" {
      for_each = (
        (!local.new_compute_environment_is_fargate)
        && var.batch_compute_config.batch_compute_environment.compute_resources.ec2_configuration != null
      ) ? [var.batch_compute_config.batch_compute_environment.compute_resources.ec2_configuration] : []
      iterator = ec2_configuration

      content {
        image_id_override = ec2_configuration.image_id_override
        image_type        = ec2_configuration.image_type
      }
    }

    # Create zero or one launch template configuration blocks
    dynamic "launch_template" {
      # The for_each iterator creation logic here is:
      #  - a launch template data source exists, only use that
      #  - OR a launch template resource exists, only use that
      #  - OR catch the all-null coalesce error and just don't create the block
      for_each = try([coalesce(
        one(data.aws_launch_template.task_batch[*].name),
        one(aws_launch_template.task_batch[*].name)
      )], [])
      iterator = launch_template

      content {
        launch_template_name = launch_template.value
      }
    }
  }

  # Create zero or one update policy configuration blocks
  dynamic "update_policy" {
    for_each = (
      var.batch_compute_config.batch_compute_environment.update_policy != null
    ) ? [var.batch_compute_config.batch_compute_environment.update_policy] : []
    iterator = update_policy

    content {
      job_execution_timeout_minutes = update_policy.job_execution_timeout_minutes
      terminate_jobs_on_update      = update_policy.terminate_jobs_on_update
    }
  }

  # Explicit dependency needed to avoid race condition during deletion
  depends_on = [aws_iam_role_policy_attachment.aws_managed_batch_service_role]

  lifecycle {
    # Create a new CE first to allow the job queue to migrate before CE deletion
    create_before_destroy = true
  }
}
# ==============================================================================


# BATCH -- JOB QUEUE AND FAIR SHARE SCHEDULING POLICY
# ------------------------------------------------------------------------------
# Either create or retrieve a job queue.
# If a job queue is created and a fair share policy configuration was provided,
# the policy will also be created and attached to the job queue.
# ------------------------------------------------------------------------------
data "aws_batch_job_queue" "task_batch" {
  count = (!local.create_job_queue) ? 1 : 0

  name = var.batch_compute_config.batch_job_queue_existing.name
}

resource "aws_batch_scheduling_policy" "task_batch" {
  count = local.create_fair_share_policy ? 1 : 0

  name = "${var.resource_prefix}-task-compute-${var.batch_compute_config.name}"

  fair_share_policy {
    compute_reservation = var.batch_compute_config.batch_job_queue.fair_share_policy.compute_reservation
    share_decay_seconds = var.batch_compute_config.batch_job_queue.fair_share_policy.share_decay_seconds

    # Create one to many share distributions
    dynamic "share_distribution" {
      for_each = var.batch_compute_config.batch_job_queue.fair_share_policy.share_distributions
      iterator = share_distribution

      content {
        share_identifier = share_distribution.value.share_identifier
        weight_factor    = share_distribution.value.weight_factor
      }
    }
  }
}

resource "aws_batch_job_queue" "task_batch" {
  count = local.create_job_queue ? 1 : 0

  name     = "${var.resource_prefix}-task-compute-${var.batch_compute_config.name}"
  state    = try(coalesce(var.batch_compute_config.batch_job_queue.state, "ENABLED"), "ENABLED")
  priority = 1

  scheduling_policy_arn = (
    local.create_fair_share_policy
    ? aws_batch_scheduling_policy.task_batch[0].arn
    : null
  )

  compute_environment_order {
    # Attach to either the compute environment data source or resource
    order = 1
    compute_environment = coalesce(
      one(data.aws_batch_compute_environment.task_batch[*].arn),
      one(aws_batch_compute_environment.task_batch[*].arn)
    )
  }
}
# ==============================================================================
