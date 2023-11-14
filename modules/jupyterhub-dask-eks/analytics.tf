resource "aws_codebuild_project" "analytics_eks_codebuild" {
  name           = "${var.kubernetes_cluster_name}-build"
  description    = "creates eks analytics cluster"
  build_timeout  = "480"
  queued_timeout = "480"
  service_role   = aws_iam_role.analytics_eks_codebuild_iam_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = "true"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "ANALYTICS_CLUSTER_NAME"
      value = var.kubernetes_cluster_name
    }

    environment_variable {
      name  = "AUTOSCALER_VERSION"
      value = var.kubernetes_autoscaler_version
    }

    environment_variable {
      name  = "VPC_CIDR_RANGE"
      value = var.vpc_cidr_range
    }

    environment_variable {
      name  = "ZONE_ID"
      value = var.zone_id
    }

    environment_variable {
      name  = "DOMAIN_ALIAS"
      value = var.domain_alias
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/filmdrop/analytics_eks_build"
      stream_name = "jupyter-dask-cluster-build"
    }
  }

  source {
    type     = "S3"
    location = "${aws_s3_bucket.jupyter_dask_source_config.arn}/"
  }

  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = var.vpc_private_subnet_ids
    security_group_ids = var.vpc_security_group_ids
  }

  depends_on = [
    aws_kms_key.analytics_filmdrop_kms_key,
    local_file.rendered_eksctl_filmdrop,
    local_file.rendered_daskhub_helm_filmdrop,
    local_file.rendered_kubectl_filmdrop_storageclass,
    local_file.rendered_kubectl_spec_filmdrop,
    module.daskhub_docker_ecr,
    aws_s3_bucket.jupyter_dask_source_config,
    aws_s3_object.jupyter_dask_source_config_ekscluster,
    aws_s3_object.jupyter_dask_source_config_spec,
    aws_s3_object.jupyter_dask_source_config_daskhub,
    aws_s3_object.jupyter_dask_source_config_storageclass,
    aws_s3_object.analytics_eks_build_spec
  ]
}

resource "null_resource" "trigger_jupyterhub_upgrade" {
  triggers = {
    new_codebuild                   = aws_codebuild_project.analytics_eks_codebuild.id
    region                          = data.aws_region.current.name
    account                         = data.aws_caller_identity.current.account_id
    filmdrop_analytics_cluster_name = var.kubernetes_cluster_name
    new_eks_config                  = aws_s3_object.jupyter_dask_source_config_ekscluster.etag
    new_spec_config                 = aws_s3_object.jupyter_dask_source_config_spec.etag
    new_dask_config                 = aws_s3_object.jupyter_dask_source_config_daskhub.etag
    new_storage_config              = aws_s3_object.jupyter_dask_source_config_storageclass.etag
    new_build_spec                  = aws_s3_object.analytics_eks_build_spec.etag

  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${data.aws_region.current.name}
export AWS_REGION=${data.aws_region.current.name}

echo "Triggering CodeBuild Project."
aws codebuild start-build --project-name ${aws_codebuild_project.analytics_eks_codebuild.id}
EOF

  }

  depends_on = [
    aws_kms_key.analytics_filmdrop_kms_key,
    local_file.rendered_eksctl_filmdrop,
    local_file.rendered_daskhub_helm_filmdrop,
    local_file.rendered_kubectl_filmdrop_storageclass,
    local_file.rendered_kubectl_spec_filmdrop,
    module.daskhub_docker_ecr,
    aws_s3_bucket.jupyter_dask_source_config,
    aws_s3_object.jupyter_dask_source_config_ekscluster,
    aws_s3_object.jupyter_dask_source_config_spec,
    aws_s3_object.jupyter_dask_source_config_daskhub,
    aws_s3_object.jupyter_dask_source_config_storageclass,
    aws_s3_object.analytics_eks_build_spec,
    aws_codebuild_project.analytics_eks_codebuild
  ]
}

module "daskhub_docker_ecr" {
  source = "./docker-images"

  vpc_id              = var.vpc_id
  private_subnet_ids  = var.vpc_private_subnet_ids
  security_group_ids  = var.vpc_security_group_ids
  project_name        = var.project_name
  daskhub_stage       = var.daskhub_stage
}

resource random_id suffix {
  byte_length = 8
}

resource "aws_s3_bucket" "jupyter_dask_source_config" {
  bucket = "jupyter-config-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_ownership_controls" "jupyter_dask_source_config_ownership_controls" {
  bucket = aws_s3_bucket.jupyter_dask_source_config.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_public_access_block" "jupyter_dask_source_config_public_access_block" {
  bucket = aws_s3_bucket.jupyter_dask_source_config.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "jupyter_dask_source_config_bucket_acl" {
  bucket = aws_s3_bucket.jupyter_dask_source_config.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "jupyter_dask_source_config_versioning" {
  bucket = aws_s3_bucket.jupyter_dask_source_config.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "jupyter_dask_source_config_ekscluster" {
  bucket = aws_s3_bucket.jupyter_dask_source_config.id
  key    = "cluster.yaml"
  source = "${path.module}/cluster.yaml"
  etag   = md5(templatefile("${path.module}/eksctl/eksctl_filmdrop.yaml.tpl",{
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
  }))
  depends_on = [
    aws_kms_key.analytics_filmdrop_kms_key,
    local_file.rendered_eksctl_filmdrop
  ]
}

resource "aws_s3_object" "jupyter_dask_source_config_spec" {
  bucket = aws_s3_bucket.jupyter_dask_source_config.id
  key    = "spec.yaml"
  source = "${path.module}/spec.yaml"
  etag   = md5(templatefile("${path.module}/kubectl/kubectl_filmdrop_spec.yaml.tpl", {
    filmdrop_analytics_cluster_name               = var.kubernetes_cluster_name
    filmdrop_analytics_cluster_autoscaler_version = var.kubernetes_autoscaler_version
  }))
  depends_on = [
    local_file.rendered_kubectl_spec_filmdrop
  ]
}

resource "aws_s3_object" "jupyter_dask_source_config_daskhub" {
  bucket = aws_s3_bucket.jupyter_dask_source_config.id
  key    = "daskhub.yaml"
  source = "${path.module}/daskhub.yaml"
  etag   = md5(templatefile("${path.module}/helm_charts/daskhub/jupyterhub.yaml.tpl", {
    jupyterhub_image_repo           = module.daskhub_docker_ecr.daskhub_repo
    jupyterhub_image_version        = var.jupyterhub_image_version
    dask_proxy_token                = jsondecode(data.aws_secretsmanager_secret_version.filmdrop_analytics_dask_secret_tokens_version.secret_string)["PROXYTOKEN"]
    jupyterhub_elb_acm_cert_arn     = var.jupyterhub_elb_acm_cert_arn
    jupyterhub_admin_username_list  = join(",", var.jupyterhub_admin_username_list)
    jupyterhub_admin_password       = jsondecode(data.aws_secretsmanager_secret_version.filmdrop_analytics_credentials_version.secret_string)["PASSWORD"]
    dask_gateway_token              = jsondecode(data.aws_secretsmanager_secret_version.filmdrop_analytics_dask_secret_tokens_version.secret_string)["APITOKEN"]
  }))
  depends_on = [
    module.daskhub_docker_ecr,
    local_file.rendered_daskhub_helm_filmdrop
  ]
}

resource "aws_s3_object" "jupyter_dask_source_config_storageclass" {
  bucket = aws_s3_bucket.jupyter_dask_source_config.id
  key    = "storageclass.yaml"
  source = "${path.module}/storageclass.yaml"
  etag   = md5(templatefile("${path.module}/kubectl/kubectl_filmdrop_storageclass.yaml.tpl",{}))
  depends_on = [
    local_file.rendered_kubectl_filmdrop_storageclass
  ]
}

resource "aws_s3_object" "analytics_eks_build_spec" {
  bucket = aws_s3_bucket.jupyter_dask_source_config.id
  key    = "buildspec.yml"
  source = "${path.module}/buildspec.yml"
  etag   = filemd5("${path.module}/buildspec.yml")
}

resource "aws_kms_key" "analytics_filmdrop_kms_key" {
  enable_key_rotation = true
}

resource "local_file" "rendered_eksctl_filmdrop" {
  depends_on = [
    aws_kms_key.analytics_filmdrop_kms_key
  ]
  content  = templatefile("${path.module}/eksctl/eksctl_filmdrop.yaml.tpl",{
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
  })
  filename = "${path.module}/cluster.yaml"
}

resource "local_file" "rendered_daskhub_helm_filmdrop" {
  depends_on = [
    module.daskhub_docker_ecr
  ]
  content  = templatefile("${path.module}/helm_charts/daskhub/jupyterhub.yaml.tpl", {
    jupyterhub_image_repo           = module.daskhub_docker_ecr.daskhub_repo
    jupyterhub_image_version        = var.jupyterhub_image_version
    dask_proxy_token                = jsondecode(data.aws_secretsmanager_secret_version.filmdrop_analytics_dask_secret_tokens_version.secret_string)["PROXYTOKEN"]
    jupyterhub_elb_acm_cert_arn     = var.jupyterhub_elb_acm_cert_arn
    jupyterhub_admin_username_list  = join(",", var.jupyterhub_admin_username_list)
    jupyterhub_admin_password       = jsondecode(data.aws_secretsmanager_secret_version.filmdrop_analytics_credentials_version.secret_string)["PASSWORD"]
    dask_gateway_token              = jsondecode(data.aws_secretsmanager_secret_version.filmdrop_analytics_dask_secret_tokens_version.secret_string)["APITOKEN"]
  })
  filename = "${path.module}/daskhub.yaml"
}

resource "local_file" "rendered_kubectl_filmdrop_storageclass" {
  content  = templatefile("${path.module}/kubectl/kubectl_filmdrop_storageclass.yaml.tpl",{})
  filename = "${path.module}/storageclass.yaml"
}

resource "local_file" "rendered_kubectl_spec_filmdrop" {
  content  = templatefile("${path.module}/kubectl/kubectl_filmdrop_spec.yaml.tpl", {
    filmdrop_analytics_cluster_name               = var.kubernetes_cluster_name
    filmdrop_analytics_cluster_autoscaler_version = var.kubernetes_autoscaler_version
  })
  filename = "${path.module}/spec.yaml"
}
