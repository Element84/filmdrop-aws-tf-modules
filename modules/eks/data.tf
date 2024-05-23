data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  # This data source provides information on the IAM source role of an STS assumed role
  # For non-role ARNs, this data source simply passes the ARN through issuer ARN
  # Ref https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2327#issuecomment-1355581682
  # Ref https://github.com/hashicorp/terraform-provider-aws/issues/28381
  arn = data.aws_caller_identity.current.arn
}

locals {
  create = var.create

  partition = data.aws_partition.current.partition

  cluster_role = try(aws_iam_role.this[0].arn, var.iam_role_arn)

  create_outposts_local_cluster    = length(var.outpost_config) > 0
  enable_cluster_encryption_config = length(var.cluster_encryption_config) > 0 && !local.create_outposts_local_cluster
}

data "tls_certificate" "this" {
  # Not available on outposts
  count = local.create_oidc_provider && var.include_oidc_root_ca_thumbprint ? 1 : 0

  url = aws_eks_cluster.this[0].identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "assume_role_policy" {
  count = local.create && var.create_iam_role ? 1 : 0

  statement {
    sid     = "EKSClusterAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    dynamic "principals" {
      for_each = local.create_outposts_local_cluster ? [1] : []

      content {
        type = "Service"
        identifiers = [
          "ec2.amazonaws.com",
        ]
      }
    }
  }
}

data "aws_eks_addon_version" "this" {
  for_each = { for k, v in var.cluster_addons : k => v if local.create && !local.create_outposts_local_cluster }

  addon_name         = try(each.value.name, each.key)
  kubernetes_version = coalesce(var.cluster_version, aws_eks_cluster.this[0].version)
  most_recent        = try(each.value.most_recent, null)
}

data "aws_iam_policy_document" "cni_ipv6_policy" {
  count = var.create && var.create_cni_ipv6_iam_policy ? 1 : 0

  statement {
    sid = "AssignDescribe"
    actions = [
      "ec2:AssignIpv6Addresses",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeInstanceTypes"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "CreateTags"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:${local.partition}:ec2:*:*:network-interface/*"]
  }
}

locals {
  create_iam_role        = local.create && var.create_iam_role
  iam_role_name          = coalesce(var.iam_role_name, "${var.cluster_name}-cluster")
  iam_role_policy_prefix = "arn:${local.partition}:iam::aws:policy"

  cluster_encryption_policy_name = coalesce(var.cluster_encryption_policy_name, "${local.iam_role_name}-ClusterEncryption")
  # This replaces the one time logic from the EKS API with something that can be
  # better controlled by users through Terraform
  bootstrap_cluster_creator_admin_permissions = {
    cluster_creator = {
      principal_arn = data.aws_iam_session_context.current.issuer_arn
      type          = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:${local.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # Merge the bootstrap behavior with the entries that users provide
  merged_access_entries = merge(
    { for k, v in local.bootstrap_cluster_creator_admin_permissions : k => v if var.enable_cluster_creator_admin_permissions },
    var.access_entries,
  )

  # Flatten out entries and policy associations so users can specify the policy
  # associations within a single entry
  flattened_access_entries = flatten([
    for entry_key, entry_val in local.merged_access_entries : [
      for pol_key, pol_val in lookup(entry_val, "policy_associations", {}) :
      merge(
        {
          principal_arn = entry_val.principal_arn
          entry_key     = entry_key
          pol_key       = pol_key
        },
        { for k, v in {
          association_policy_arn              = pol_val.policy_arn
          association_access_scope_type       = pol_val.access_scope.type
          association_access_scope_namespaces = lookup(pol_val.access_scope, "namespaces", [])
        } : k => v if !contains(["EC2_LINUX", "EC2_WINDOWS", "FARGATE_LINUX"], lookup(entry_val, "type", "STANDARD")) },
      )
    ]
  ])
  cluster_sg_name   = coalesce(var.cluster_security_group_name, "${var.cluster_name}-cluster")
  create_cluster_sg = local.create && var.create_cluster_security_group

  cluster_security_group_id = local.create_cluster_sg ? aws_security_group.cluster[0].id : var.cluster_security_group_id

  # Do not add rules to node security group if the module is not creating it
  cluster_security_group_rules = { for k, v in {
    ingress_nodes_443 = {
      description                = "Node groups to cluster API"
      protocol                   = "tcp"
      from_port                  = 443
      to_port                    = 443
      type                       = "ingress"
      source_node_security_group = true
    }
  } : k => v if local.create_node_sg }
  # Not available on outposts
  create_oidc_provider = local.create && var.enable_irsa && !local.create_outposts_local_cluster

  oidc_root_ca_thumbprint = local.create_oidc_provider && var.include_oidc_root_ca_thumbprint ? [data.tls_certificate.this[0].certificates[0].sha1_fingerprint] : []
}
