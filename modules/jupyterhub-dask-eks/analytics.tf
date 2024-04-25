resource "aws_codebuild_project" "analytics_eks_codebuild" {
  name                   = "${local.kubernetes_cluster_name}-build"
  description            = "creates eks analytics cluster"
  concurrent_build_limit = 1
  build_timeout          = "480"
  queued_timeout         = "480"
  service_role           = aws_iam_role.analytics_eks_codebuild_iam_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
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
      value = local.kubernetes_cluster_name
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

    environment_variable {
      name  = "DOMAIN_PARAM_NAME"
      value = var.domain_param_name == "" ? local.kubernetes_cluster_name : var.domain_param_name
    }

    environment_variable {
      name  = "LAMBDA_NAME"
      value = aws_lambda_function.cloudfront_origin_lambda.function_name
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
    local_file.rendered_kubectl_autoscaler_filmdrop,
    module.daskhub_docker_ecr,
    aws_s3_bucket.jupyter_dask_source_config,
    aws_s3_object.jupyter_dask_source_config_ekscluster,
    aws_s3_object.jupyter_dask_source_config_spec,
    aws_s3_object.jupyter_dask_source_config_autoscaler,
    aws_s3_object.jupyter_dask_source_config_daskhub,
    aws_s3_object.jupyter_dask_source_config_storageclass,
    aws_s3_object.analytics_eks_build_spec
  ]
}

resource "aws_s3_bucket_notification" "jupyter_dask_source_config_notifications" {
  bucket      = aws_s3_bucket.jupyter_dask_source_config.id
  eventbridge = true
}

module "daskhub_docker_ecr" {
  source = "./docker-images"

  vpc_id             = var.vpc_id
  private_subnet_ids = var.vpc_private_subnet_ids
  security_group_ids = var.vpc_security_group_ids
  project_name       = var.project_name
  daskhub_stage      = var.daskhub_stage
}

resource "random_id" "suffix" {
  byte_length = 8
}

resource "aws_s3_bucket" "jupyter_dask_source_config" {
  bucket_prefix = lower("${local.kubernetes_cluster_name}-jd-cfg-")
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "jupyter_dask_source_config_ownership_controls" {
  bucket = aws_s3_bucket.jupyter_dask_source_config.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "jupyter_dask_source_config_public_access_block" {
  bucket = aws_s3_bucket.jupyter_dask_source_config.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
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
  etag = md5(templatefile("${path.module}/eksctl/eksctl_filmdrop.yaml.tpl", {
    filmdrop_analytics_cluster_name = local.kubernetes_cluster_name
    filmdrop_kubernetes_version     = var.kubernetes_version
    filmdrop_region                 = data.aws_region.current.name
    filmdrop_private_subnet_map     = jsonencode(zipmap(var.vpc_private_subnet_azs, var.vpc_private_subnet_ids))
    filmdrop_public_subnet_map      = jsonencode(zipmap(var.vpc_public_subnet_azs, var.vpc_public_subnet_ids))
    filmdrop_private_subnet_azs     = length(var.analytics_worker_node_azs) == 0 ? jsonencode([var.vpc_private_subnet_azs[0]]) : jsonencode(var.analytics_worker_node_azs)
    filmdrop_public_subnet_azs      = length(var.analytics_main_node_azs) == 0 ? jsonencode([var.vpc_public_subnet_azs[0]]) : jsonencode(var.analytics_main_node_azs)
    filmdrop_kms_key_arn            = aws_kms_key.analytics_filmdrop_kms_key.arn
    daskhub_instance_types          = jsonencode(var.daskhub_nodegroup_instance_types)
    jupyterhub_instance_types       = jsonencode(var.jupyterhub_nodegroup_instance_types)
    jupyterhub_min_size             = var.jupyterhub_nodegroup_min_size
    jupyterhub_max_size             = var.jupyterhub_nodegroup_max_size
    daskhub_min_size                = var.daskhub_nodegroup_min_size
    daskhub_max_size                = var.daskhub_nodegroup_max_size
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
  etag = md5(templatefile("${path.module}/kubectl/kubectl_filmdrop_spec.yaml.tpl", {
    filmdrop_analytics_cluster_name               = local.kubernetes_cluster_name
    filmdrop_analytics_cluster_autoscaler_version = var.kubernetes_autoscaler_version
  }))
  depends_on = [
    local_file.rendered_kubectl_spec_filmdrop
  ]
}

resource "aws_s3_object" "jupyter_dask_source_config_autoscaler" {
  bucket = aws_s3_bucket.jupyter_dask_source_config.id
  key    = "autoscaler.yaml"
  source = "${path.module}/autoscaler.yaml"
  etag = md5(templatefile("${path.module}/kubectl/kubectl_filmdrop_cluster_autoscaler.yaml.tpl", {
    filmdrop_analytics_cluster_name               = local.kubernetes_cluster_name
    filmdrop_analytics_cluster_autoscaler_version = var.kubernetes_autoscaler_version
  }))
  depends_on = [
    local_file.rendered_kubectl_autoscaler_filmdrop
  ]
}

resource "aws_s3_object" "jupyter_dask_source_config_daskhub" {
  bucket = aws_s3_bucket.jupyter_dask_source_config.id
  key    = "daskhub.yaml"
  source = "${path.module}/daskhub.yaml"
  etag = md5(templatefile(var.jupyterhub_elb_acm_cert_arn == "" ? "${path.module}/helm_charts/daskhub/jupyterhub_http.yaml.tpl" : "${path.module}/helm_charts/daskhub/jupyterhub.yaml.tpl", {
    jupyterhub_image_repo          = module.daskhub_docker_ecr.daskhub_repo
    jupyterhub_image_version       = var.jupyterhub_image_version
    dask_proxy_token               = jsondecode(data.aws_secretsmanager_secret_version.filmdrop_analytics_dask_secret_token_version.secret_string)["PROXYTOKEN"]
    jupyterhub_elb_acm_cert_arn    = var.jupyterhub_elb_acm_cert_arn
    jupyterhub_admin_username_list = join(",", var.jupyterhub_admin_username_list)
    jupyterhub_admin_password      = jsondecode(data.aws_secretsmanager_secret_version.filmdrop_analytics_credentials_version.secret_string)["PASSWORD"]
    dask_gateway_token             = jsondecode(data.aws_secretsmanager_secret_version.filmdrop_analytics_dask_secret_token_version.secret_string)["APITOKEN"]
    filmdrop_public_subnet_ids     = var.vpc_public_subnet_ids[0]
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
  etag   = md5(templatefile("${path.module}/kubectl/kubectl_filmdrop_storageclass.yaml.tpl", {}))
  depends_on = [
    local_file.rendered_kubectl_filmdrop_storageclass
  ]
}

resource "aws_s3_object" "analytics_eks_build_spec" {
  bucket = aws_s3_bucket.jupyter_dask_source_config.id
  key    = "buildspec.yml"
  source = var.zone_id != "" && var.domain_alias != "" ? "${path.module}/buildspec.yml" : "${path.module}/buildspec_nodnsalias.yml"
  etag   = filemd5(var.zone_id != "" && var.domain_alias != "" ? "${path.module}/buildspec.yml" : "${path.module}/buildspec_nodnsalias.yml")
}

resource "aws_kms_key" "analytics_filmdrop_kms_key" {
  enable_key_rotation = true
}

resource "local_file" "rendered_eksctl_filmdrop" {
  depends_on = [
    aws_kms_key.analytics_filmdrop_kms_key
  ]
  content = templatefile("${path.module}/eksctl/eksctl_filmdrop.yaml.tpl", {
    filmdrop_analytics_cluster_name = local.kubernetes_cluster_name
    filmdrop_kubernetes_version     = var.kubernetes_version
    filmdrop_region                 = data.aws_region.current.name
    filmdrop_private_subnet_map     = jsonencode(zipmap(var.vpc_private_subnet_azs, var.vpc_private_subnet_ids))
    filmdrop_public_subnet_map      = jsonencode(zipmap(var.vpc_public_subnet_azs, var.vpc_public_subnet_ids))
    filmdrop_private_subnet_azs     = length(var.analytics_worker_node_azs) == 0 ? jsonencode([var.vpc_private_subnet_azs[0]]) : jsonencode(var.analytics_worker_node_azs)
    filmdrop_public_subnet_azs      = length(var.analytics_main_node_azs) == 0 ? jsonencode([var.vpc_public_subnet_azs[0]]) : jsonencode(var.analytics_main_node_azs)
    filmdrop_kms_key_arn            = aws_kms_key.analytics_filmdrop_kms_key.arn
    daskhub_instance_types          = jsonencode(var.daskhub_nodegroup_instance_types)
    jupyterhub_instance_types       = jsonencode(var.jupyterhub_nodegroup_instance_types)
    jupyterhub_min_size             = var.jupyterhub_nodegroup_min_size
    jupyterhub_max_size             = var.jupyterhub_nodegroup_max_size
    daskhub_min_size                = var.daskhub_nodegroup_min_size
    daskhub_max_size                = var.daskhub_nodegroup_max_size
  })
  filename = "${path.module}/cluster.yaml"
}

resource "local_file" "rendered_daskhub_helm_filmdrop" {
  depends_on = [
    module.daskhub_docker_ecr
  ]
  content = templatefile(var.jupyterhub_elb_acm_cert_arn == "" ? "${path.module}/helm_charts/daskhub/jupyterhub_http.yaml.tpl" : "${path.module}/helm_charts/daskhub/jupyterhub.yaml.tpl", {
    jupyterhub_image_repo          = module.daskhub_docker_ecr.daskhub_repo
    jupyterhub_image_version       = var.jupyterhub_image_version
    dask_proxy_token               = jsondecode(data.aws_secretsmanager_secret_version.filmdrop_analytics_dask_secret_token_version.secret_string)["PROXYTOKEN"]
    jupyterhub_elb_acm_cert_arn    = var.jupyterhub_elb_acm_cert_arn
    jupyterhub_admin_username_list = join(",", var.jupyterhub_admin_username_list)
    jupyterhub_admin_password      = jsondecode(data.aws_secretsmanager_secret_version.filmdrop_analytics_credentials_version.secret_string)["PASSWORD"]
    dask_gateway_token             = jsondecode(data.aws_secretsmanager_secret_version.filmdrop_analytics_dask_secret_token_version.secret_string)["APITOKEN"]
    filmdrop_public_subnet_ids     = var.vpc_public_subnet_ids[0]
  })
  filename = "${path.module}/daskhub.yaml"
}

resource "local_file" "rendered_kubectl_filmdrop_storageclass" {
  content  = templatefile("${path.module}/kubectl/kubectl_filmdrop_storageclass.yaml.tpl", {})
  filename = "${path.module}/storageclass.yaml"
}

resource "local_file" "rendered_kubectl_spec_filmdrop" {
  content = templatefile("${path.module}/kubectl/kubectl_filmdrop_spec.yaml.tpl", {
    filmdrop_analytics_cluster_name               = local.kubernetes_cluster_name
    filmdrop_analytics_cluster_autoscaler_version = var.kubernetes_autoscaler_version
  })
  filename = "${path.module}/spec.yaml"
}

resource "local_file" "rendered_kubectl_autoscaler_filmdrop" {
  content = templatefile("${path.module}/kubectl/kubectl_filmdrop_cluster_autoscaler.yaml.tpl", {
    filmdrop_analytics_cluster_name               = local.kubernetes_cluster_name
    filmdrop_analytics_cluster_autoscaler_version = var.kubernetes_autoscaler_version
  })
  filename = "${path.module}/autoscaler.yaml"
}

resource "aws_lambda_function" "cloudfront_origin_lambda" {
  filename         = data.archive_file.cloudfront_origin_lambda_zip.output_path
  source_code_hash = data.archive_file.cloudfront_origin_lambda_zip.output_base64sha256
  function_name    = "fd-${var.project_name}-${var.environment}-analytics-origin"
  role             = aws_iam_role.cloudfront_origin_lambda_role.arn
  description      = "Sets CloudFront Custom Origin"
  handler          = "main.lambda_handler"
  runtime          = "python3.9"
  timeout          = "60"

  environment {
    variables = {
      DISTRIBUTIONID   = var.cloudfront_distribution_id
      SSM_ORIGIN_PARAM = var.domain_param_name
    }
  }
}

resource "null_resource" "trigger_jupyterhub_upgrade" {
  triggers = {
    new_codebuild                   = aws_codebuild_project.analytics_eks_codebuild.id
    region                          = data.aws_region.current.name
    account                         = data.aws_caller_identity.current.account_id
    filmdrop_analytics_cluster_name = local.kubernetes_cluster_name
    cloudfront_distribution_id      = var.cloudfront_distribution_id
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-ec"]
    command     = <<EOF
export AWS_DEFAULT_REGION=${data.aws_region.current.name}
export AWS_REGION=${data.aws_region.current.name}

echo "Triggering CodeBuild Project."
START_RESULT=$(aws codebuild start-build --project-name ${aws_codebuild_project.analytics_eks_codebuild.id})
BUILD_ID=$(echo $START_RESULT | jq '.build.id' -r)

BUILD_STATUS="IN_PROGRESS"
while [[ "$BUILD_STATUS" == "IN_PROGRESS" ]]; do
    sleep 5
    BUILD=$(aws codebuild batch-get-builds --ids $BUILD_ID)
    BUILD_STATUS=$(echo $BUILD | jq '.builds[0].buildStatus' -r)
    if [[ "$BUILD_STATUS" == "IN_PROGRESS" ]]; then
        echo "CodeBuild is still in progress..."
    fi
done

if [[ "$BUILD_STATUS" != "SUCCEEDED" ]]; then
    LOG_URL=$(echo $BUILD | jq '.builds[0].logs.deepLink' -r)
    echo "Build failed - logs are available at [$LOG_URL]"
    exit 1
else
    echo "console UI CodeBuild succeeded"
fi
EOF

  }

  depends_on = [
    aws_kms_key.analytics_filmdrop_kms_key,
    local_file.rendered_eksctl_filmdrop,
    local_file.rendered_daskhub_helm_filmdrop,
    local_file.rendered_kubectl_filmdrop_storageclass,
    local_file.rendered_kubectl_spec_filmdrop,
    local_file.rendered_kubectl_autoscaler_filmdrop,
    module.daskhub_docker_ecr,
    aws_s3_bucket.jupyter_dask_source_config,
    aws_s3_object.jupyter_dask_source_config_ekscluster,
    aws_s3_object.jupyter_dask_source_config_spec,
    aws_s3_object.jupyter_dask_source_config_autoscaler,
    aws_s3_object.jupyter_dask_source_config_daskhub,
    aws_s3_object.jupyter_dask_source_config_storageclass,
    aws_s3_object.analytics_eks_build_spec,
    aws_codebuild_project.analytics_eks_codebuild
  ]
}

resource "null_resource" "cleanup_bucket" {
  triggers = {
    bucket_name = aws_s3_bucket.jupyter_dask_source_config.id
    region      = data.aws_region.current.name
    account     = data.aws_caller_identity.current.account_id
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}

echo "FilmDrop CloudFront bucket has been created."

aws s3 ls s3://${self.triggers.bucket_name}
EOF

  }


  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}

echo "Cleaning FilmDrop bucket."

aws s3 rm s3://${self.triggers.bucket_name}/ --recursive
EOF
  }


  depends_on = [
    aws_s3_bucket.jupyter_dask_source_config
  ]
}

module "analytics_cleanup" {
  count  = var.analytics_cleanup_enabled ? 1 : 0
  source = "./cleanup"

  analytics_cluster_name                       = local.kubernetes_cluster_name
  analytics_cleanup_stage                      = var.daskhub_stage
  analytics_asg_min_capacity                   = var.analytics_asg_min_capacity
  analytics_node_limit                         = var.analytics_node_limit
  analytics_notifications_schedule_expressions = var.analytics_notifications_schedule_expressions
  analytics_cleanup_schedule_expressions       = var.analytics_cleanup_schedule_expressions

  depends_on = [
    aws_kms_key.analytics_filmdrop_kms_key,
    local_file.rendered_eksctl_filmdrop,
    local_file.rendered_daskhub_helm_filmdrop,
    local_file.rendered_kubectl_filmdrop_storageclass,
    local_file.rendered_kubectl_spec_filmdrop,
    local_file.rendered_kubectl_autoscaler_filmdrop,
    module.daskhub_docker_ecr,
    aws_s3_bucket.jupyter_dask_source_config,
    aws_s3_object.jupyter_dask_source_config_ekscluster,
    aws_s3_object.jupyter_dask_source_config_spec,
    aws_s3_object.jupyter_dask_source_config_autoscaler,
    aws_s3_object.jupyter_dask_source_config_daskhub,
    aws_s3_object.jupyter_dask_source_config_storageclass,
    aws_s3_object.analytics_eks_build_spec,
    aws_codebuild_project.analytics_eks_codebuild,
    null_resource.trigger_jupyterhub_upgrade
  ]
}
