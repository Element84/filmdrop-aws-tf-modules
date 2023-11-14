# EKS Cluster
resource "aws_eks_cluster" "cluster" {
  name      = var.cluster_name
  role_arn  = aws_iam_role.cluster_role.arn
  version   = var.cluster_version

  vpc_config  {
    subnet_ids  = var.subnet_ids
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
  ]
}

# EKS Node Group
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "workers"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.node_group_instance_type

  scaling_config {
    desired_size = var.autoscaling_group_desired_capacity
    max_size     = var.autoscaling_group_max_size
    min_size     = var.autoscaling_group_min_size
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEBSCSIDriverPolicy,
    resource.aws_eks_cluster.cluster
  ]
}

resource "aws_eks_addon" "ebs-csi-driver-addon" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "aws-ebs-csi-driver"
  addon_version      = "v1.17.0-eksbuild.1"

  depends_on = [
    aws_eks_node_group.node_group
  ]
}

