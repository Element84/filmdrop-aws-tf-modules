module "eks_cluster" {
  source = "github.com/terraform-aws-modules/terraform-aws-eks?ref=v20.4.0"

  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_endpoint_public_access  = var.endpoint_public_access
  cluster_endpoint_private_access = var.endpoint_private_access

  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.control_plane_subnet_ids
  control_plane_subnet_ids = var.node_group_subnet_ids

  # External encryption key
  create_kms_key = false
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = module.eks_cluster_kms.key_arn
  }

  eks_managed_node_group_defaults = {
    ami_type       = var.eks_managed_node_group.ami_type
    instance_types = var.eks_managed_node_group.instance_types
  }

  eks_managed_node_groups = {
    filmdrop-managed-group = {
      min_size       = var.eks_managed_node_group.autoscaling_group_min_size
      max_size       = var.eks_managed_node_group.autoscaling_group_max_size
      desired_size   = var.eks_managed_node_group.autoscaling_group_desired_capacity
      instance_types = var.eks_managed_node_group.instance_types
      capacity_type  = var.eks_managed_node_group.node_group_capacity_type

      ebs_optimized     = true
      enable_monitoring = true

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.eks_managed_node_group.node_group_disk_size_gb
            volume_type           = var.eks_managed_node_group.node_group_volume_type
            encrypted             = true
            kms_key_id            = module.ebs_kms_key.key_arn
            delete_on_termination = true
          }
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      create_iam_role          = true
      iam_role_name            = var.eks_managed_node_group.node_group_name
      iam_role_use_name_prefix = true
      iam_role_description     = "${var.eks_managed_node_group.node_group_name} role"

      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
        AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        AmazonEBSCSIDriverPolicy           = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonS3ReadOnlyAccess             = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
        AmazonElasticFileSystemFullAccess  = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
        CloudWatchAgentServerPolicy        = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
        AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        additional                         = aws_iam_policy.eks_worker_node_filmdrop_policy.arn
      }
      tags = {
        Name = "FilmDrop EKS ${var.eks_managed_node_group.node_group_name} Nodes"
      }
    }
  }

  self_managed_node_group_defaults = {
    # enable discovery of autoscaling groups by cluster-autoscaler
    autoscaling_group_tags = {
      "k8s.io/cluster-autoscaler/enabled" : true,
      "k8s.io/cluster-autoscaler/${var.cluster_name}" : "owned",
    }
  }

  self_managed_node_groups = {
    # Default node group - as provisioned by the module defaults
    default_node_group = {}

    # Bottlerocket node group
    filmdrop-self-managed-group = {
      name = var.eks_self_managed_node_group.node_group_name

      platform      = "bottlerocket"
      ami_id        = data.aws_ami.eks_default_bottlerocket.id
      instance_type = var.eks_self_managed_node_group.instance_type
      subnet_ids    = var.eks_self_managed_node_group.subnet_ids
      min_size      = var.eks_self_managed_node_group.autoscaling_group_min_size
      max_size      = var.eks_self_managed_node_group.autoscaling_group_max_size
      desired_size  = var.eks_self_managed_node_group.autoscaling_group_desired_capacity
      key_name      = module.eks_key_pair.key_pair_name

      bootstrap_extra_args = <<-EOT
        # The admin host container provides SSH access and runs with "superpowers".
        # It is disabled by default, but can be disabled explicitly.
        [settings.host-containers.admin]
        enabled = false

        # The control host container provides out-of-band access via SSM.
        # It is enabled by default, and can be disabled if you do not expect to use SSM.
        # This could leave you with no way to access the API and change settings on an existing node!
        [settings.host-containers.control]
        enabled = true

        # extra args added
        [settings.kernel]
        lockdown = "integrity"

        [settings.kubernetes.node-labels]
        application = "filmdrop"
        service = "storage"

        [settings.kubernetes.node-taints]
        dedicated = "experimental:PreferNoSchedule"
        special = "true:NoSchedule"
      EOT

      ebs_optimized     = true
      enable_monitoring = true

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.eks_self_managed_node_group.node_group_disk_size_gb
            volume_type           = var.eks_self_managed_node_group.node_group_volume_type
            encrypted             = true
            kms_key_id            = module.ebs_kms_key.key_arn
            delete_on_termination = true
          }
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      create_iam_role          = true
      iam_role_name            = var.eks_self_managed_node_group.node_group_name
      iam_role_use_name_prefix = true
      iam_role_description     = "${var.eks_self_managed_node_group.node_group_name} role"

      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
        AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        AmazonEBSCSIDriverPolicy           = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonS3ReadOnlyAccess             = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
        AmazonElasticFileSystemFullAccess  = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
        CloudWatchAgentServerPolicy        = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
        AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        additional                         = aws_iam_policy.eks_worker_node_filmdrop_policy.arn
      }
      tags = {
        Name = "FilmDrop EKS ${var.eks_self_managed_node_group.node_group_name} Nodes"
      }
    }
  }

  node_security_group_additional_rules = {
    # Extend node-to-node security group rules. Recommended and required for the Add-ons
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    ingress_cluster_to_node_all_traffic = {
      description              = "Cluster API to Nodegroup all traffic"
      protocol                 = "-1"
      from_port                = 0
      to_port                  = 0
      type                     = "ingress"
      source_security_group_id = module.eks_cluster.cluster_security_group_id
    }
  }

}


module "disabled_self_managed_node_group" {
  source = "github.com/terraform-aws-modules/terraform-aws-eks//modules/self-managed-node-group?ref=v20.4.0"

  create = false
}


module "eks_key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.0"

  key_name_prefix    = var.cluster_name
  create_private_key = true
}

module "ebs_kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 2.0"

  description = "Customer managed key to encrypt EKS managed node group volumes"

  # Policy
  key_administrators = [
    data.aws_caller_identity.current.arn
  ]

  key_service_roles_for_autoscaling = [
    # required for the ASG to manage encrypted volumes for nodes
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    # required for the cluster / persistentvolume-controller to create encrypted PVCs
    module.eks_cluster.cluster_iam_role_arn,
  ]

  # Aliases
  aliases = ["eks/${var.cluster_name}/ebs"]
}

module "eks_cluster_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 2.1"

  aliases               = ["eks/${var.cluster_name}"]
  description           = "${var.cluster_name} cluster encryption key"
  enable_default_policy = true
  key_owners            = [data.aws_caller_identity.current.arn]
}

resource "aws_security_group_rule" "allow_node_sg_to_cluster_sg" {
  description = "Self-Node Group to Cluster API/MNG all traffic"

  source_security_group_id = module.eks_cluster.node_security_group_id
  security_group_id        = module.eks_cluster.cluster_primary_security_group_id
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0

  depends_on = [
    module.eks_cluster
  ]
}

resource "aws_security_group_rule" "allow_node_sg_from_cluster_sg" {
  description              = "Cluster API/MNG to Self-Nodegroup all traffic"
  source_security_group_id = module.eks_cluster.cluster_primary_security_group_id
  security_group_id        = module.eks_cluster.node_security_group_id
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0

  depends_on = [
    module.eks_cluster
  ]
}

resource "aws_eks_addon" "ebs-csi-driver-addon" {
  cluster_name  = var.cluster_name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = "v1.17.0-eksbuild.1"

  depends_on = [
    module.eks_cluster
  ]
}
