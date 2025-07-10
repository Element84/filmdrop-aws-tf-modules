module "analytics_certificate" {
  source = "./cert"
  count  = var.analytics_inputs.jupyterhub_elb_acm_cert_arn == "" ? 1 : 0

  domain_zone  = var.domain_zone
  domain_alias = var.analytics_inputs.jupyterhub_elb_domain_alias
}

module "create_credentials" {
  source = "./credentials"

  create_credentials      = var.analytics_inputs.create_credentials
  credentials_name_prefix = "fd-analytics-${var.project_name}-${var.environment}"
}


module "jupyterhub-dask-eks" {
  source = "../../modules/jupyterhub-dask-eks"

  vpc_id                                       = var.vpc_id
  vpc_private_subnet_ids                       = var.private_subnet_ids
  vpc_security_group_ids                       = [var.security_group_id]
  vpc_cidr_range                               = var.vpc_cidr
  vpc_public_subnet_ids                        = var.public_subnet_ids
  vpc_private_subnet_azs                       = var.private_availability_zones
  vpc_public_subnet_azs                        = var.public_availability_zones
  jupyterhub_elb_acm_cert_arn                  = var.analytics_inputs.jupyterhub_elb_acm_cert_arn == "" ? module.analytics_certificate[0].certificate_arn : var.analytics_inputs.jupyterhub_elb_acm_cert_arn
  project_name                                 = var.project_name
  environment                                  = var.environment
  zone_id                                      = var.domain_zone
  domain_alias                                 = var.analytics_inputs.jupyterhub_elb_domain_alias
  daskhub_stage                                = var.environment
  domain_param_name                            = module.cloudfront_load_balancer_endpoint.cloudfront_domain_origin_param
  cloudfront_distribution_id                   = module.cloudfront_load_balancer_endpoint.cloudfront_distribution_id
  analytics_cleanup_enabled                    = var.analytics_inputs.cleanup.enabled
  analytics_asg_min_capacity                   = var.analytics_inputs.cleanup.asg_min_capacity
  analytics_node_limit                         = var.analytics_inputs.cleanup.analytics_node_limit
  analytics_notifications_schedule_expressions = var.analytics_inputs.cleanup.notifications_schedule_expressions
  analytics_cleanup_schedule_expressions       = var.analytics_inputs.cleanup.cleanup_schedule_expressions
  kubernetes_version                           = var.analytics_inputs.eks.cluster_version
  kubernetes_autoscaler_version                = var.analytics_inputs.eks.autoscaler_version

  depends_on = [
    module.create_credentials
  ]
}

module "cloudfront_load_balancer_endpoint" {
  source = "../../modules/cloudfront/lb_endpoint"

  providers = {
    aws.east = aws.east
  }

  zone_id                      = var.domain_zone
  domain_alias                 = var.analytics_inputs.domain_alias
  application_name             = var.analytics_inputs.app_name
  create_log_bucket            = var.create_log_bucket
  log_bucket_name              = var.log_bucket_name
  log_bucket_domain_name       = var.log_bucket_domain_name
  filmdrop_archive_bucket_name = var.s3_logs_archive_bucket
  load_balancer_dns_name       = var.analytics_inputs.jupyterhub_elb_domain_alias
  web_acl_id                   = var.analytics_inputs.web_acl_id == "" ? var.fd_web_acl_id : var.analytics_inputs.web_acl_id
  project_name                 = var.project_name
  environment                  = var.environment
  cf_function_name             = var.analytics_inputs.auth_function.cf_function_name
  cf_function_runtime          = var.analytics_inputs.auth_function.cf_function_runtime
  cf_function_code_path        = var.analytics_inputs.auth_function.cf_function_code_path
  attach_cf_function           = var.analytics_inputs.auth_function.attach_cf_function
  cf_function_event_type       = var.analytics_inputs.auth_function.cf_function_event_type
  create_cf_function           = var.analytics_inputs.auth_function.create_cf_function
  create_cf_basicauth_function = var.analytics_inputs.auth_function.create_cf_basicauth_function
  cf_function_arn              = var.analytics_inputs.auth_function.cf_function_arn
}

resource "null_resource" "cleanup_analytics_credentials" {
  count = var.analytics_inputs.create_credentials ? 1 : 0

  triggers = {
    filmdrop_analytics_dask_secret_token = "fd-analytics-${var.project_name}-${var.environment}-admin-credentials"
    filmdrop_analytics_credentials       = "fd-analytics-${var.project_name}-${var.environment}-dask-token"
    region                               = data.aws_region.current.name
    account                              = data.aws_caller_identity.current.account_id
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}

echo "FilmDrop Analytics Secrets have been created."

aws secretsmanager describe-secret --secret-id ${self.triggers.filmdrop_analytics_dask_secret_token}
aws secretsmanager describe-secret --secret-id ${self.triggers.filmdrop_analytics_credentials}
EOF

  }


  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}

echo "Cleaning FilmDrop Analytics Secrets."

aws secretsmanager delete-secret --secret-id ${self.triggers.filmdrop_analytics_dask_secret_token} --force-delete-without-recovery --region ${self.triggers.region}
aws secretsmanager delete-secret --secret-id ${self.triggers.filmdrop_analytics_credentials} --force-delete-without-recovery --region ${self.triggers.region}
EOF
  }


  depends_on = [
    module.jupyterhub-dask-eks,
    module.create_credentials,
    module.cloudfront_load_balancer_endpoint
  ]
}

resource "null_resource" "cleanup_analytics_stack" {
  triggers = {
    filmdrop_analytics_cluster_name = "fd-analytics-${var.project_name}-${var.environment}"
    domain_param_name               = module.cloudfront_load_balancer_endpoint.cloudfront_domain_origin_param
    region                          = data.aws_region.current.name
    account                         = data.aws_caller_identity.current.account_id
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}

echo "FilmDrop Analytics Stack has been created."

EOF

  }


  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}


echo "Deleting Analytics Stack and Load Balancer."
aws cloudformation delete-stack --stack-name eksctl-${self.triggers.filmdrop_analytics_cluster_name}-nodegroup-dask-workers
aws cloudformation delete-stack --stack-name eksctl-${self.triggers.filmdrop_analytics_cluster_name}-nodegroup-main
aws cloudformation delete-stack --stack-name eksctl-${self.triggers.filmdrop_analytics_cluster_name}-addon-iamserviceaccount-kube-system-ebs-csi-controller-sa
aws cloudformation delete-stack --stack-name eksctl-${self.triggers.filmdrop_analytics_cluster_name}-addon-iamserviceaccount-kube-system-cluster-autoscaler
aws cloudformation delete-stack --stack-name eksctl-${self.triggers.filmdrop_analytics_cluster_name}-addon-iamserviceaccount-kube-system-aws-node
aws cloudformation wait stack-delete-complete --stack-name eksctl-${self.triggers.filmdrop_analytics_cluster_name}-nodegroup-dask-workers
aws cloudformation wait stack-delete-complete --stack-name eksctl-${self.triggers.filmdrop_analytics_cluster_name}-nodegroup-main
aws cloudformation wait stack-delete-complete --stack-name eksctl-${self.triggers.filmdrop_analytics_cluster_name}-addon-iamserviceaccount-kube-system-ebs-csi-controller-sa
aws cloudformation wait stack-delete-complete --stack-name eksctl-${self.triggers.filmdrop_analytics_cluster_name}-addon-iamserviceaccount-kube-system-cluster-autoscaler
aws cloudformation wait stack-delete-complete --stack-name eksctl-${self.triggers.filmdrop_analytics_cluster_name}-addon-iamserviceaccount-kube-system-aws-node
aws cloudformation delete-stack --stack-name eksctl-${self.triggers.filmdrop_analytics_cluster_name}-cluster
aws cloudformation wait stack-delete-complete --stack-name eksctl-${self.triggers.filmdrop_analytics_cluster_name}-cluster
JUPYTERHUB_LB_DNS=`aws ssm get-parameter --name ${self.triggers.domain_param_name} --region us-east-1 | jq -r '.Parameter.Value'`
JUPYTERHUB_LB_ID=`echo "$JUPYTERHUB_LB_DNS" | cut -d'-' -f1`
aws elb delete-load-balancer --load-balancer-name $JUPYTERHUB_LB_ID
EOF
  }


  depends_on = [
    module.jupyterhub-dask-eks,
    module.create_credentials,
    module.cloudfront_load_balancer_endpoint
  ]
}
