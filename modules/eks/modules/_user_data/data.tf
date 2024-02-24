# https://github.com/aws/containers-roadmap/issues/596#issuecomment-675097667
# An important note is that user data must in MIME multi-part archive format,
# as by default, EKS will merge the bootstrapping command required for nodes to join the
# cluster with your user data. If you use a custom AMI in your launch template,
# this merging will NOT happen and you are responsible for nodes joining the cluster.
# See docs for more details -> https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-user-data

data "cloudinit_config" "linux_eks_managed_node_group" {
  count = var.create && var.platform == "linux" && var.is_eks_managed_node_group && !var.enable_bootstrap_user_data && var.pre_bootstrap_user_data != "" && var.user_data_template_path == "" ? 1 : 0

  base64_encode = true
  gzip          = false
  boundary      = "//"

  # Prepend to existing user data supplied by AWS EKS
  part {
    content_type = "text/x-shellscript"
    content      = var.pre_bootstrap_user_data
  }
}
