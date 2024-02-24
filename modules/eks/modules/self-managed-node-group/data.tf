data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

data "aws_ami" "eks_default" {
  count = var.create && var.create_launch_template ? 1 : 0

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}-v*"]
  }

  most_recent = true
  owners      = ["amazon"]
}

data "aws_ec2_instance_type" "this" {
  count = var.enable_efa_support && local.instance_type_provided ? 1 : 0

  instance_type = var.instance_type
}

data "aws_iam_policy_document" "assume_role_policy" {
  count = var.create && var.create_iam_instance_profile ? 1 : 0

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
    values = [var.instance_type]
  }

  location_type = "availability-zone-id"
}

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
  instance_type_provided = var.instance_type != ""
  num_network_cards      = try(data.aws_ec2_instance_type.this[0].maximum_network_cards, 0)

  efa_network_interfaces = [
    for i in range(local.num_network_cards) : {
      associate_public_ip_address = false
      delete_on_termination       = true
      device_index                = i == 0 ? 0 : 1
      network_card_index          = i
      interface_type              = "efa"
    }
  ]

  network_interfaces   = var.enable_efa_support && local.instance_type_provided ? local.efa_network_interfaces : var.network_interfaces
  launch_template_name = coalesce(var.launch_template_name, "${var.name}-node-group")
  security_group_ids   = compact(concat([var.cluster_primary_security_group_id], var.vpc_security_group_ids))

  placement              = var.create && var.enable_efa_support ? { group_name = aws_placement_group.this[0].name } : var.placement
  iam_role_name          = coalesce(var.iam_role_name, "${var.name}-node-group")
  iam_role_policy_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"
  cni_policy             = var.cluster_ip_family == "ipv6" ? "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/AmazonEKS_CNI_IPv6_Policy" : "${local.iam_role_policy_prefix}/AmazonEKS_CNI_Policy"
  launch_template_id     = var.create && var.create_launch_template ? aws_launch_template.this[0].id : var.launch_template_id
  # Change order to allow users to set version priority before using defaults
  launch_template_version = coalesce(var.launch_template_version, try(aws_launch_template.this[0].default_version, "$Default"))
}
