data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ec2_instance_type" "this" {
  count = var.enable_efa_support ? 1 : 0

  instance_type = local.efa_instance_type
}

data "aws_iam_policy_document" "assume_role_policy" {
  count = var.create && var.create_iam_role ? 1 : 0

  statement {
    sid     = "EKSNodeAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_ec2_instance_type_offerings" "this" {
  count = var.create && var.enable_efa_support ? 1 : 0

  filter {
    name   = "instance-type"
    values = [local.efa_instance_type]
  }

  location_type = "availability-zone-id"
}

# Reverse the lookup to find one of the subnets provided based on the availability
# availability zone ID of the queried instance type (supported)
data "aws_subnets" "efa" {
  count = var.create && var.enable_efa_support ? 1 : 0

  filter {
    name   = "subnet-id"
    values = var.subnet_ids
  }

  filter {
    name   = "availability-zone-id"
    values = data.aws_ec2_instance_type_offerings.this[0].locations
  }
}


locals {
  efa_instance_type = try(element(var.instance_types, 0), "")
  num_network_cards = try(data.aws_ec2_instance_type.this[0].maximum_network_cards, 0)

  efa_network_interfaces = [
    for i in range(local.num_network_cards) : {
      associate_public_ip_address = false
      delete_on_termination       = true
      device_index                = i == 0 ? 0 : 1
      network_card_index          = i
      interface_type              = "efa"
    }
  ]

  network_interfaces     = var.enable_efa_support ? local.efa_network_interfaces : var.network_interfaces
  iam_role_name          = coalesce(var.iam_role_name, "${var.name}-eks-node-group")
  iam_role_policy_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"
  cni_policy             = var.cluster_ip_family == "ipv6" ? "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/AmazonEKS_CNI_IPv6_Policy" : "${local.iam_role_policy_prefix}/AmazonEKS_CNI_Policy"
  launch_template_name   = coalesce(var.launch_template_name, "${var.name}-eks-node-group")
  security_group_ids     = compact(concat([var.cluster_primary_security_group_id], var.vpc_security_group_ids))

  placement          = var.create && var.enable_efa_support ? { group_name = aws_placement_group.this[0].name } : var.placement
  launch_template_id = var.create && var.create_launch_template ? try(aws_launch_template.this[0].id, null) : var.launch_template_id
  # Change order to allow users to set version priority before using defaults
  launch_template_version = coalesce(var.launch_template_version, try(aws_launch_template.this[0].default_version, "$Default"))
}
