################################################################################
# EKS Cluster configuration
# Supports managed, self-managed and fargate node groups
# References:
# * https://github.com/aws-ia/terraform-aws-eks-blueprints (versions < 5.0)
# * https://github.com/terraform-aws-modules/terraform-aws-eks (versions >= 2.0)
################################################################################

resource "aws_eks_cluster" "this" {
  count = local.create ? 1 : 0

  name                      = var.cluster_name
  role_arn                  = local.cluster_role
  version                   = var.cluster_version
  enabled_cluster_log_types = var.cluster_enabled_log_types

  access_config {
    authentication_mode = var.authentication_mode

    # See access entries below - this is a one time operation from the EKS API.
    # Instead, we are hardcoding this to false and if users wish to achieve this
    # same functionality, we will do that through an access entry which can be
    # enabled or disabled at any time of their choosing using the variable
    # var.enable_cluster_creator_admin_permissions
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    security_group_ids      = compact(distinct(concat(var.cluster_additional_security_group_ids, [local.cluster_security_group_id])))
    subnet_ids              = coalescelist(var.control_plane_subnet_ids, var.subnet_ids)
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  dynamic "kubernetes_network_config" {
    # Not valid on Outposts
    for_each = local.create_outposts_local_cluster ? [] : [1]

    content {
      ip_family         = var.cluster_ip_family
      service_ipv4_cidr = var.cluster_service_ipv4_cidr
      service_ipv6_cidr = var.cluster_service_ipv6_cidr
    }
  }

  dynamic "outpost_config" {
    for_each = local.create_outposts_local_cluster ? [var.outpost_config] : []

    content {
      control_plane_instance_type = outpost_config.value.control_plane_instance_type
      outpost_arns                = outpost_config.value.outpost_arns
    }
  }

  dynamic "encryption_config" {
    # Not available on Outposts
    for_each = local.enable_cluster_encryption_config ? [var.cluster_encryption_config] : []

    content {
      provider {
        key_arn = var.create_kms_key ? module.kms.key_arn : encryption_config.value.provider_key_arn
      }
      resources = encryption_config.value.resources
    }
  }

  tags = merge(
    { terraform-aws-modules = "eks" },
    var.tags,
    var.cluster_tags,
  )

  timeouts {
    create = try(var.cluster_timeouts.create, null)
    update = try(var.cluster_timeouts.update, null)
    delete = try(var.cluster_timeouts.delete, null)
  }

  depends_on = [
    aws_iam_role_policy_attachment.this,
    aws_security_group_rule.cluster,
    aws_security_group_rule.node,
    aws_cloudwatch_log_group.this,
    aws_iam_policy.cni_ipv6_policy,
  ]
}

resource "aws_ec2_tag" "cluster_primary_security_group" {
  # This should not affect the name of the cluster primary security group
  # Ref: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2006
  # Ref: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2008
  for_each = { for k, v in merge(var.tags, var.cluster_tags) :
    k => v if local.create && k != "Name" && var.create_cluster_primary_security_group_tags && v != null
  }

  resource_id = aws_eks_cluster.this[0].vpc_config[0].cluster_security_group_id
  key         = each.key
  value       = each.value
}

resource "aws_cloudwatch_log_group" "this" {
  count = local.create && var.create_cloudwatch_log_group ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id
  log_group_class   = var.cloudwatch_log_group_class

  tags = merge(
    var.tags,
    var.cloudwatch_log_group_tags,
    { Name = "/aws/eks/${var.cluster_name}/cluster" }
  )
}

################################################################################
# Access Entry
################################################################################
resource "aws_eks_access_entry" "this" {
  for_each = { for k, v in local.merged_access_entries : k => v if local.create }

  cluster_name      = aws_eks_cluster.this[0].name
  kubernetes_groups = try(each.value.kubernetes_groups, null)
  principal_arn     = each.value.principal_arn
  type              = try(each.value.type, "STANDARD")
  user_name         = try(each.value.user_name, null)

  tags = merge(var.tags, try(each.value.tags, {}))
}

resource "aws_eks_access_policy_association" "this" {
  for_each = { for k, v in local.flattened_access_entries : "${v.entry_key}_${v.pol_key}" => v if local.create }

  access_scope {
    namespaces = try(each.value.association_access_scope_namespaces, [])
    type       = each.value.association_access_scope_type
  }

  cluster_name = aws_eks_cluster.this[0].name

  policy_arn    = each.value.association_policy_arn
  principal_arn = each.value.principal_arn

  depends_on = [
    aws_eks_access_entry.this,
  ]
}

################################################################################
# KMS Key
################################################################################

module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "2.1.0" # Note - be mindful of Terraform/provider version compatibility between modules

  create = local.create && var.create_kms_key && local.enable_cluster_encryption_config # not valid on Outposts

  description             = coalesce(var.kms_key_description, "${var.cluster_name} cluster encryption key")
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.enable_kms_key_rotation

  # Policy
  enable_default_policy     = var.kms_key_enable_default_policy
  key_owners                = var.kms_key_owners
  key_administrators        = coalescelist(var.kms_key_administrators, [data.aws_iam_session_context.current.issuer_arn])
  key_users                 = concat([local.cluster_role], var.kms_key_users)
  key_service_users         = var.kms_key_service_users
  source_policy_documents   = var.kms_key_source_policy_documents
  override_policy_documents = var.kms_key_override_policy_documents

  # Aliases
  aliases = var.kms_key_aliases
  computed_aliases = {
    # Computed since users can pass in computed values for cluster name such as random provider resources
    cluster = { name = "eks/${var.cluster_name}" }
  }

  tags = merge(
    { terraform-aws-modules = "eks" },
    var.tags,
  )
}

################################################################################
# Cluster Security Group
# Defaults follow https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html
################################################################################
resource "aws_security_group" "cluster" {
  count = local.create_cluster_sg ? 1 : 0

  name        = var.cluster_security_group_use_name_prefix ? null : local.cluster_sg_name
  name_prefix = var.cluster_security_group_use_name_prefix ? "${local.cluster_sg_name}${var.prefix_separator}" : null
  description = var.cluster_security_group_description
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    { "Name" = local.cluster_sg_name },
    var.cluster_security_group_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "cluster" {
  for_each = { for k, v in merge(
    local.cluster_security_group_rules,
    var.cluster_security_group_additional_rules
  ) : k => v if local.create_cluster_sg }

  # Required
  security_group_id = aws_security_group.cluster[0].id
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  type              = each.value.type

  # Optional
  description              = lookup(each.value, "description", null)
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks         = lookup(each.value, "ipv6_cidr_blocks", null)
  prefix_list_ids          = lookup(each.value, "prefix_list_ids", null)
  self                     = lookup(each.value, "self", null)
  source_security_group_id = try(each.value.source_node_security_group, false) ? local.node_security_group_id : lookup(each.value, "source_security_group_id", null)
}

################################################################################
# IRSA
# Note - this is different from EKS identity provider
################################################################################
resource "aws_iam_openid_connect_provider" "oidc_provider" {
  # Not available on outposts
  count = local.create_oidc_provider ? 1 : 0

  client_id_list  = distinct(compact(concat(["sts.amazonaws.com"], var.openid_connect_audiences)))
  thumbprint_list = concat(local.oidc_root_ca_thumbprint, var.custom_oidc_thumbprints)
  url             = aws_eks_cluster.this[0].identity[0].oidc[0].issuer

  tags = merge(
    { Name = "${var.cluster_name}-eks-irsa" },
    var.tags
  )
}

################################################################################
# IAM Role
################################################################################

resource "aws_iam_role" "this" {
  count = local.create_iam_role ? 1 : 0

  name        = var.iam_role_use_name_prefix ? null : local.iam_role_name
  name_prefix = var.iam_role_use_name_prefix ? "${local.iam_role_name}${var.prefix_separator}" : null
  path        = var.iam_role_path
  description = var.iam_role_description

  assume_role_policy    = data.aws_iam_policy_document.assume_role_policy[0].json
  permissions_boundary  = var.iam_role_permissions_boundary
  force_detach_policies = true

  # https://github.com/terraform-aws-modules/terraform-aws-eks/issues/920
  # Resources running on the cluster are still generating logs when destroying the module resources
  # which results in the log group being re-created even after Terraform destroys it. Removing the
  # ability for the cluster role to create the log group prevents this log group from being re-created
  # outside of Terraform due to services still generating logs during destroy process
  dynamic "inline_policy" {
    for_each = var.create_cloudwatch_log_group ? [1] : []
    content {
      name = local.iam_role_name

      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action   = ["logs:CreateLogGroup"]
            Effect   = "Deny"
            Resource = "*"
          },
        ]
      })
    }
  }

  tags = merge(var.tags, var.iam_role_tags)
}

# Policies attached ref https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html
resource "aws_iam_role_policy_attachment" "this" {
  for_each = { for k, v in {
    AmazonEKSClusterPolicy         = local.create_outposts_local_cluster ? "${local.iam_role_policy_prefix}/AmazonEKSLocalOutpostClusterPolicy" : "${local.iam_role_policy_prefix}/AmazonEKSClusterPolicy",
    AmazonEKSVPCResourceController = "${local.iam_role_policy_prefix}/AmazonEKSVPCResourceController",
  } : k => v if local.create_iam_role }

  policy_arn = each.value
  role       = aws_iam_role.this[0].name
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = { for k, v in var.iam_role_additional_policies : k => v if local.create_iam_role }

  policy_arn = each.value
  role       = aws_iam_role.this[0].name
}

# Using separate attachment due to `The "for_each" value depends on resource attributes that cannot be determined until apply`
resource "aws_iam_role_policy_attachment" "cluster_encryption" {
  # Encryption config not available on Outposts
  count = local.create_iam_role && var.attach_cluster_encryption_policy && local.enable_cluster_encryption_config ? 1 : 0

  policy_arn = aws_iam_policy.cluster_encryption[0].arn
  role       = aws_iam_role.this[0].name
}

resource "aws_iam_policy" "cluster_encryption" {
  # Encryption config not available on Outposts
  count = local.create_iam_role && var.attach_cluster_encryption_policy && local.enable_cluster_encryption_config ? 1 : 0

  name        = var.cluster_encryption_policy_use_name_prefix ? null : local.cluster_encryption_policy_name
  name_prefix = var.cluster_encryption_policy_use_name_prefix ? local.cluster_encryption_policy_name : null
  description = var.cluster_encryption_policy_description
  path        = var.cluster_encryption_policy_path

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ListGrants",
          "kms:DescribeKey",
        ]
        Effect   = "Allow"
        Resource = var.create_kms_key ? module.kms.key_arn : var.cluster_encryption_config.provider_key_arn
      },
    ]
  })

  tags = merge(var.tags, var.cluster_encryption_policy_tags)
}

################################################################################
# EKS Addons
################################################################################
resource "aws_eks_addon" "this" {
  # Not supported on outposts
  for_each = { for k, v in var.cluster_addons : k => v if !try(v.before_compute, false) && local.create && !local.create_outposts_local_cluster }

  cluster_name = aws_eks_cluster.this[0].name
  addon_name   = try(each.value.name, each.key)

  addon_version               = coalesce(try(each.value.addon_version, null), data.aws_eks_addon_version.this[each.key].version)
  configuration_values        = try(each.value.configuration_values, null)
  preserve                    = try(each.value.preserve, true)
  resolve_conflicts_on_create = try(each.value.resolve_conflicts_on_create, "OVERWRITE")
  resolve_conflicts_on_update = try(each.value.resolve_conflicts_on_update, "OVERWRITE")
  service_account_role_arn    = try(each.value.service_account_role_arn, null)

  timeouts {
    create = try(each.value.timeouts.create, var.cluster_addons_timeouts.create, null)
    update = try(each.value.timeouts.update, var.cluster_addons_timeouts.update, null)
    delete = try(each.value.timeouts.delete, var.cluster_addons_timeouts.delete, null)
  }

  depends_on = [
    module.fargate_profile,
    module.eks_managed_node_group,
    module.self_managed_node_group,
  ]

  tags = merge(var.tags, try(each.value.tags, {}))
}

resource "aws_eks_addon" "before_compute" {
  # Not supported on outposts
  for_each = { for k, v in var.cluster_addons : k => v if try(v.before_compute, false) && local.create && !local.create_outposts_local_cluster }

  cluster_name = aws_eks_cluster.this[0].name
  addon_name   = try(each.value.name, each.key)

  addon_version               = coalesce(try(each.value.addon_version, null), data.aws_eks_addon_version.this[each.key].version)
  configuration_values        = try(each.value.configuration_values, null)
  preserve                    = try(each.value.preserve, true)
  resolve_conflicts_on_create = try(each.value.resolve_conflicts_on_create, "OVERWRITE")
  resolve_conflicts_on_update = try(each.value.resolve_conflicts_on_update, "OVERWRITE")
  service_account_role_arn    = try(each.value.service_account_role_arn, null)

  timeouts {
    create = try(each.value.timeouts.create, var.cluster_addons_timeouts.create, null)
    update = try(each.value.timeouts.update, var.cluster_addons_timeouts.update, null)
    delete = try(each.value.timeouts.delete, var.cluster_addons_timeouts.delete, null)
  }

  tags = merge(var.tags, try(each.value.tags, {}))
}

################################################################################
# EKS Identity Provider
# Note - this is different from IRSA
################################################################################

resource "aws_eks_identity_provider_config" "this" {
  for_each = { for k, v in var.cluster_identity_providers : k => v if local.create && !local.create_outposts_local_cluster }

  cluster_name = aws_eks_cluster.this[0].name

  oidc {
    client_id                     = each.value.client_id
    groups_claim                  = lookup(each.value, "groups_claim", null)
    groups_prefix                 = lookup(each.value, "groups_prefix", null)
    identity_provider_config_name = try(each.value.identity_provider_config_name, each.key)
    issuer_url                    = try(each.value.issuer_url, aws_eks_cluster.this[0].identity[0].oidc[0].issuer)
    required_claims               = lookup(each.value, "required_claims", null)
    username_claim                = lookup(each.value, "username_claim", null)
    username_prefix               = lookup(each.value, "username_prefix", null)
  }

  tags = merge(var.tags, try(each.value.tags, {}))
}
