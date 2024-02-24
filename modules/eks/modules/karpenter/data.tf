data "aws_region" "current" {}
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "controller_assume_role" {
  count = local.create_iam_role ? 1 : 0

  # Pod Identity
  dynamic "statement" {
    for_each = var.enable_pod_identity ? [1] : []

    content {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession",
      ]

      principals {
        type        = "Service"
        identifiers = ["pods.eks.amazonaws.com"]
      }
    }
  }

  # IAM Roles for Service Accounts (IRSA)
  dynamic "statement" {
    for_each = var.enable_irsa ? [1] : []

    content {
      actions = ["sts:AssumeRoleWithWebIdentity"]

      principals {
        type        = "Federated"
        identifiers = [var.irsa_oidc_provider_arn]
      }

      condition {
        test     = var.irsa_assume_role_condition_test
        variable = "${local.irsa_oidc_provider_url}:sub"
        values   = [for sa in var.irsa_namespace_service_accounts : "system:serviceaccount:${sa}"]
      }

      # https://aws.amazon.com/premiumsupport/knowledge-center/eks-troubleshoot-oidc-and-irsa/?nc1=h_ls
      condition {
        test     = var.irsa_assume_role_condition_test
        variable = "${local.irsa_oidc_provider_url}:aud"
        values   = ["sts.amazonaws.com"]
      }
    }
  }
}

data "aws_iam_policy_document" "controller" {
  count = local.create_iam_role ? 1 : 0

  statement {
    sid = "AllowScopedEC2InstanceActions"
    resources = [
      "arn:${local.partition}:ec2:*::image/*",
      "arn:${local.partition}:ec2:*::snapshot/*",
      "arn:${local.partition}:ec2:*:*:spot-instances-request/*",
      "arn:${local.partition}:ec2:*:*:security-group/*",
      "arn:${local.partition}:ec2:*:*:subnet/*",
      "arn:${local.partition}:ec2:*:*:launch-template/*",
    ]

    actions = [
      "ec2:RunInstances",
      "ec2:CreateFleet"
    ]
  }

  statement {
    sid = "AllowScopedEC2InstanceActionsWithTags"
    resources = [
      "arn:${local.partition}:ec2:*:*:fleet/*",
      "arn:${local.partition}:ec2:*:*:instance/*",
      "arn:${local.partition}:ec2:*:*:volume/*",
      "arn:${local.partition}:ec2:*:*:network-interface/*",
      "arn:${local.partition}:ec2:*:*:launch-template/*",
      "arn:${local.partition}:ec2:*:*:spot-instances-request/*",
    ]
    actions = [
      "ec2:RunInstances",
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.sh/nodepool"
      values   = ["*"]
    }
  }

  statement {
    sid = "AllowScopedResourceCreationTagging"
    resources = [
      "arn:${local.partition}:ec2:*:*:fleet/*",
      "arn:${local.partition}:ec2:*:*:instance/*",
      "arn:${local.partition}:ec2:*:*:volume/*",
      "arn:${local.partition}:ec2:*:*:network-interface/*",
      "arn:${local.partition}:ec2:*:*:launch-template/*",
      "arn:${local.partition}:ec2:*:*:spot-instances-request/*",
    ]
    actions = ["ec2:CreateTags"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values = [
        "RunInstances",
        "CreateFleet",
        "CreateLaunchTemplate",
      ]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.sh/nodepool"
      values   = ["*"]
    }
  }

  statement {
    sid       = "AllowScopedResourceTagging"
    resources = ["arn:${local.partition}:ec2:*:*:instance/*"]
    actions   = ["ec2:CreateTags"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.sh/nodepool"
      values   = ["*"]
    }

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "aws:TagKeys"
      values = [
        "karpenter.sh/nodeclaim",
        "Name",
      ]
    }
  }

  statement {
    sid = "AllowScopedDeletion"
    resources = [
      "arn:${local.partition}:ec2:*:*:instance/*",
      "arn:${local.partition}:ec2:*:*:launch-template/*"
    ]

    actions = [
      "ec2:TerminateInstances",
      "ec2:DeleteLaunchTemplate"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.sh/nodepool"
      values   = ["*"]
    }
  }

  statement {
    sid       = "AllowRegionalReadActions"
    resources = ["*"]
    actions = [
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [local.region]
    }
  }

  statement {
    sid       = "AllowSSMReadActions"
    resources = coalescelist(var.ami_id_ssm_parameter_arns, ["arn:${local.partition}:ssm:${local.region}::parameter/aws/service/*"])
    actions   = ["ssm:GetParameter"]
  }

  statement {
    sid       = "AllowPricingReadActions"
    resources = ["*"]
    actions   = ["pricing:GetProducts"]
  }

  dynamic "statement" {
    for_each = local.enable_spot_termination ? [1] : []

    content {
      sid       = "AllowInterruptionQueueActions"
      resources = [try(aws_sqs_queue.this[0].arn, null)]
      actions = [
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ReceiveMessage"
      ]
    }
  }

  statement {
    sid       = "AllowPassingInstanceRole"
    resources = var.create_node_iam_role ? [aws_iam_role.node[0].arn] : [var.node_iam_role_arn]
    actions   = ["iam:PassRole"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }

  statement {
    sid       = "AllowScopedInstanceProfileCreationActions"
    resources = ["*"]
    actions   = ["iam:CreateInstanceProfile"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/topology.kubernetes.io/region"
      values   = [local.region]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"
      values   = ["*"]
    }
  }

  statement {
    sid       = "AllowScopedInstanceProfileTagActions"
    resources = ["*"]
    actions   = ["iam:TagInstanceProfile"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/topology.kubernetes.io/region"
      values   = [local.region]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/topology.kubernetes.io/region"
      values   = [local.region]
    }

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass"
      values   = ["*"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"
      values   = ["*"]
    }
  }

  statement {
    sid       = "AllowScopedInstanceProfileActions"
    resources = ["*"]
    actions = [
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:DeleteInstanceProfile"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/topology.kubernetes.io/region"
      values   = [local.region]
    }

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass"
      values   = ["*"]
    }
  }

  statement {
    sid       = "AllowInstanceProfileReadActions"
    resources = ["*"]
    actions   = ["iam:GetInstanceProfile"]
  }

  statement {
    sid       = "AllowAPIServerEndpointDiscovery"
    resources = ["arn:${local.partition}:eks:${local.region}:${local.account_id}:cluster/${var.cluster_name}"]
    actions   = ["eks:DescribeCluster"]
  }
}

data "aws_iam_policy_document" "queue" {
  count = local.enable_spot_termination ? 1 : 0

  statement {
    sid       = "SqsWrite"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.this[0].arn]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "sqs.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "node_assume_role" {
  count = local.create_node_iam_role ? 1 : 0

  statement {
    sid     = "EKSNodeAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

locals {
  account_id             = data.aws_caller_identity.current.account_id
  partition              = data.aws_partition.current.partition
  region                 = data.aws_region.current.name
  create_iam_role        = var.create && var.create_iam_role
  irsa_oidc_provider_url = replace(var.irsa_oidc_provider_arn, "/^(.*provider/)/", "")
  events = {
    health_event = {
      name        = "HealthEvent"
      description = "Karpenter interrupt - AWS health event"
      event_pattern = {
        source      = ["aws.health"]
        detail-type = ["AWS Health Event"]
      }
    }
    spot_interrupt = {
      name        = "SpotInterrupt"
      description = "Karpenter interrupt - EC2 spot instance interruption warning"
      event_pattern = {
        source      = ["aws.ec2"]
        detail-type = ["EC2 Spot Instance Interruption Warning"]
      }
    }
    instance_rebalance = {
      name        = "InstanceRebalance"
      description = "Karpenter interrupt - EC2 instance rebalance recommendation"
      event_pattern = {
        source      = ["aws.ec2"]
        detail-type = ["EC2 Instance Rebalance Recommendation"]
      }
    }
    instance_state_change = {
      name        = "InstanceStateChange"
      description = "Karpenter interrupt - EC2 instance state-change notification"
      event_pattern = {
        source      = ["aws.ec2"]
        detail-type = ["EC2 Instance State-change Notification"]
      }
    }
  }
  create_node_iam_role = var.create && var.create_node_iam_role

  node_iam_role_name          = coalesce(var.node_iam_role_name, "Karpenter-${var.cluster_name}")
  node_iam_role_policy_prefix = "arn:${local.partition}:iam::aws:policy"
  cni_policy                  = var.cluster_ip_family == "ipv6" ? "arn:${local.partition}:iam::${local.account_id}:policy/AmazonEKS_CNI_IPv6_Policy" : "${local.node_iam_role_policy_prefix}/AmazonEKS_CNI_Policy"
  enable_spot_termination     = var.create && var.enable_spot_termination

  queue_name         = coalesce(var.queue_name, "Karpenter-${var.cluster_name}")
  external_role_name = try(replace(var.node_iam_role_arn, "/^(.*role/)/", ""), null)
}
