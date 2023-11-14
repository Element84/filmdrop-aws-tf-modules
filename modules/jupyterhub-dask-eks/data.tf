data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

data "aws_secretsmanager_secret_version" "filmdrop_analytics_credentials_version" {
  secret_id     = var.filmdrop_analytics_jupyterhub_admin_credentials_secret
}

data "aws_secretsmanager_secret_version" "filmdrop_analytics_dask_secret_tokens_version" {
  secret_id     = var.filmdrop_analytics_dask_secret_tokens
}

data "template_file" "kubectl_spec_filmdrop" {
  template = file("${path.module}/kubectl/kubectl_filmdrop_spec.yaml.tpl")
  vars = {
    filmdrop_analytics_cluster_name               = var.kubernetes_cluster_name
    filmdrop_analytics_cluster_autoscaler_version = var.kubernetes_autoscaler_version
  }
}

data "template_file" "daskhub_helm_filmdrop" {
  template = file("${path.module}/helm_charts/daskhub/jupyterhub.yaml.tpl")
  depends_on = [
    module.daskhub_docker_ecr
  ]
  vars = {
    jupyterhub_image_repo           = module.daskhub_docker_ecr.daskhub_repo
    jupyterhub_image_version        = var.jupyterhub_image_version
    dask_proxy_token                = jsondecode(data.aws_secretsmanager_secret_version.filmdrop_analytics_dask_secret_tokens_version.secret_string)["PROXYTOKEN"]
    jupyterhub_elb_acm_cert_arn     = var.jupyterhub_elb_acm_cert_arn
    jupyterhub_admin_username_list  = join(",", var.jupyterhub_admin_username_list)
    jupyterhub_admin_password       = jsondecode(data.aws_secretsmanager_secret_version.filmdrop_analytics_credentials_version.secret_string)["PASSWORD"]
    dask_gateway_token              = jsondecode(data.aws_secretsmanager_secret_version.filmdrop_analytics_dask_secret_tokens_version.secret_string)["APITOKEN"]
  }
}

data "template_file" "kubectl_filmdrop_storageclass" {
  depends_on = [
    data.template_file.kubectl_spec_filmdrop
  ]
  template = file("${path.module}/kubectl/kubectl_filmdrop_storageclass.yaml.tpl")
}

data "template_file" "eksctl_filmdrop" {
  depends_on = [
    aws_kms_key.analytics_filmdrop_kms_key
  ]
  template = file("${path.module}/eksctl/eksctl_filmdrop.yaml.tpl")
  vars = {
    filmdrop_analytics_cluster_name   = var.kubernetes_cluster_name
    filmdrop_kubernetes_version       = var.kubernetes_version
    filmdrop_region                   = data.aws_region.current.name
    filmdrop_private_subnet_map       = jsonencode(zipmap(var.vpc_private_subnet_azs, var.vpc_private_subnet_ids))
    filmdrop_public_subnet_map        = jsonencode(zipmap(var.vpc_public_subnet_azs, var.vpc_public_subnet_ids))
    filmdrop_private_subnet_azs       = length(var.analytics_worker_node_azs) == 0 ? jsonencode([var.vpc_private_subnet_azs[0]]) : jsonencode(var.analytics_worker_node_azs)
    filmdrop_public_subnet_azs        = length(var.analytics_main_node_azs) == 0 ? jsonencode([var.vpc_public_subnet_azs[0]]) : jsonencode(var.analytics_main_node_azs)
    filmdrop_kms_key_arn              = aws_kms_key.analytics_filmdrop_kms_key.arn
    daskhub_instance_types            = jsonencode(var.daskhub_nodegroup_instance_types)
    jupyterhub_instance_types         = jsonencode(var.jupyterhub_nodegroup_instance_types)
    jupyterhub_min_size               = var.jupyterhub_nodegroup_min_size
    jupyterhub_max_size               = var.jupyterhub_nodegroup_max_size
    daskhub_min_size                  = var.daskhub_nodegroup_min_size
    daskhub_max_size                  = var.daskhub_nodegroup_max_size
  }
}
