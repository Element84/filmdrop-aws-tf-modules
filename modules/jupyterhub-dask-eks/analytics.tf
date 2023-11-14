resource "null_resource" "create_eks_cluster" {
  triggers = {
    region                          = data.aws_region.current.name
    account                         = data.aws_caller_identity.current.account_id
    filmdrop_analytics_cluster_name = var.kubernetes_cluster_name
    new_cluster_definition          = aws_s3_object.jupyter_dask_source_config_ekscluster.etag
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.region}
export AWS_REGION=${self.triggers.region}

echo "Deleting eks cluster if it already exists ..."
aws eks update-kubeconfig --name ${self.triggers.filmdrop_analytics_cluster_name} --region ${self.triggers.region} 2> /dev/null
eksctl delete cluster --name ${self.triggers.filmdrop_analytics_cluster_name} 2> /dev/null

echo "Creating eks cluster ..."
eksctl create cluster -f ${path.module}/cluster.yaml

EOF

  }

  provisioner "local-exec" {
    when          = destroy
    command       = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.region}
export AWS_REGION=${self.triggers.region}

echo "Delete eks cluster on destroy"
aws eks update-kubeconfig --name ${self.triggers.filmdrop_analytics_cluster_name} --region ${self.triggers.region} 2> /dev/null
eksctl delete cluster --name ${self.triggers.filmdrop_analytics_cluster_name}  2> /dev/null

EOF
  }

  depends_on = [
    aws_kms_key.analytics_filmdrop_kms_key,
    data.template_file.eksctl_filmdrop,
    data.template_file.kubectl_spec_filmdrop,
    data.template_file.daskhub_helm_filmdrop,
    data.template_file.kubectl_filmdrop_storageclass,
    local_file.rendered_eksctl_filmdrop,
    local_file.rendered_daskhub_helm_filmdrop,
    local_file.rendered_kubectl_filmdrop_storageclass,
    local_file.rendered_kubectl_spec_filmdrop,
    module.daskhub_docker_ecr,
    aws_s3_bucket.jupyter_dask_source_config,
    aws_s3_object.jupyter_dask_source_config_ekscluster,
    aws_s3_object.jupyter_dask_source_config_spec,
    aws_s3_object.jupyter_dask_source_config_daskhub,
    aws_s3_object.jupyter_dask_source_config_storageclass
  ]
}

resource "null_resource" "create_kubectl_autoscaler" {
  triggers = {
    region                          = data.aws_region.current.name
    account                         = data.aws_caller_identity.current.account_id
    filmdrop_analytics_cluster_name = var.kubernetes_cluster_name
    kubernetes_autoscaler_version   = var.kubernetes_autoscaler_version
    new_cluster_spec                = aws_s3_object.jupyter_dask_source_config_spec.etag
    new_eks_cluster                 = null_resource.create_eks_cluster.id
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.region}
export AWS_REGION=${self.triggers.region}

echo "Creating cluster autoscaler ..."
aws eks update-kubeconfig --name ${self.triggers.filmdrop_analytics_cluster_name} --region ${self.triggers.region}
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
kubectl annotate serviceaccount cluster-autoscaler -n kube-system eks.amazonaws.com/role-arn=arn:aws:iam::${self.triggers.account}:role/eksctl-cluster-autoscaler-role
kubectl patch deployment cluster-autoscaler -n kube-system -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict":"false"}}}}}'
kubectl patch deployment cluster-autoscaler -n kube-system --patch-file ${path.module}/spec.yaml
kubectl set image deployment cluster-autoscaler -n kube-system cluster-autoscaler=k8s.gcr.io/autoscaling/cluster-autoscaler:${self.triggers.kubernetes_autoscaler_version}

EOF

  }


  depends_on = [
    aws_kms_key.analytics_filmdrop_kms_key,
    data.template_file.eksctl_filmdrop,
    data.template_file.kubectl_spec_filmdrop,
    data.template_file.daskhub_helm_filmdrop,
    data.template_file.kubectl_filmdrop_storageclass,
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
    null_resource.create_eks_cluster
  ]
}

resource "null_resource" "create_storage_class" {
  triggers = {
    region                          = data.aws_region.current.name
    account                         = data.aws_caller_identity.current.account_id
    filmdrop_analytics_cluster_name = var.kubernetes_cluster_name
    new_storage_class               = aws_s3_object.jupyter_dask_source_config_storageclass.etag
    new_eks_cluster                 = null_resource.create_eks_cluster.id
    new_kubectl_autoscaler          = null_resource.create_kubectl_autoscaler.id
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.region}
export AWS_REGION=${self.triggers.region}

echo "Deleting storageclass if it already exists ..."
aws eks update-kubeconfig --name ${self.triggers.filmdrop_analytics_cluster_name} --region ${self.triggers.region} 2> /dev/null
helm delete aws-ebs-csi-driver 2> /dev/null

echo "Adding storageclass ..."
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm upgrade --install --debug aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver --namespace kube-system --set image.repository=602401143452.dkr.ecr.${self.triggers.region}.amazonaws.com/eks/aws-ebs-csi-driver --set controller.serviceAccount.create=true --set controller.serviceAccount.name=ebs-csi-controller-sa --set controller.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ebs-csi-driver-role"
kubectl replace -f ${path.module}/storageclass.yaml --force


EOF

  }

  provisioner "local-exec" {
    when          = destroy
    command       = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.region}
export AWS_REGION=${self.triggers.region}

echo "Deleting storageclass on destroy ..."
aws eks update-kubeconfig --name ${self.triggers.filmdrop_analytics_cluster_name} --region ${self.triggers.region} 2> /dev/null
helm delete aws-ebs-csi-driver  2> /dev/null

EOF
  }


  depends_on = [
    aws_kms_key.analytics_filmdrop_kms_key,
    data.template_file.eksctl_filmdrop,
    data.template_file.kubectl_spec_filmdrop,
    data.template_file.daskhub_helm_filmdrop,
    data.template_file.kubectl_filmdrop_storageclass,
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
    null_resource.create_eks_cluster,
    null_resource.create_kubectl_autoscaler
  ]
}

resource "null_resource" "create_dask_helm" {
  triggers = {
    region                          = data.aws_region.current.name
    account                         = data.aws_caller_identity.current.account_id
    filmdrop_analytics_cluster_name = var.kubernetes_cluster_name
    new_helm_daskhub                = aws_s3_object.jupyter_dask_source_config_daskhub.etag
    new_eks_cluster                 = null_resource.create_eks_cluster.id
    new_kubectl_autoscaler          = null_resource.create_kubectl_autoscaler.id
    new_storage_class               = null_resource.create_storage_class.id
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.region}
export AWS_REGION=${self.triggers.region}

echo "Deleting storageclass if it already exists ..."
aws eks update-kubeconfig --name ${self.triggers.filmdrop_analytics_cluster_name} --region ${self.triggers.region} 2> /dev/null
helm delete daskhub 2> /dev/null

echo "Adding dask helm ..."
aws ecr get-login-password --region ${self.triggers.region} | docker login --username AWS --password-stdin ${self.triggers.account}.dkr.ecr.${self.triggers.region}.amazonaws.com
helm repo add dask https://helm.dask.org/
helm repo update
helm upgrade --install --debug daskhub dask/daskhub --values=${path.module}/daskhub.yaml --timeout=30m


EOF

  }

  provisioner "local-exec" {
    when          = destroy
    command       = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.region}
export AWS_REGION=${self.triggers.region}

echo "Deleting dask helm on destroy ..."
aws eks update-kubeconfig --name ${self.triggers.filmdrop_analytics_cluster_name} --region ${self.triggers.region} 2> /dev/null
helm delete daskhub  2> /dev/null

EOF
  }


  depends_on = [
    aws_kms_key.analytics_filmdrop_kms_key,
    data.template_file.eksctl_filmdrop,
    data.template_file.kubectl_spec_filmdrop,
    data.template_file.daskhub_helm_filmdrop,
    data.template_file.kubectl_filmdrop_storageclass,
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
    null_resource.create_eks_cluster,
    null_resource.create_kubectl_autoscaler,
    null_resource.create_storage_class
  ]
}

resource "null_resource" "authorize_vpc_sg" {
  triggers = {
    region                          = data.aws_region.current.name
    account                         = data.aws_caller_identity.current.account_id
    filmdrop_analytics_cluster_name = var.kubernetes_cluster_name
    vpc_cidr_range                  = var.vpc_cidr_range
    new_helm_daskhub                = null_resource.create_dask_helm.id
    new_eks_cluster                 = null_resource.create_eks_cluster.id
    new_kubectl_autoscaler          = null_resource.create_kubectl_autoscaler.id
    new_storage_class               = null_resource.create_storage_class.id
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.region}
export AWS_REGION=${self.triggers.region}

echo "Deleting SG rule if it already exists ..."
SUBNET_ID=`aws ec2 describe-security-groups --region ${self.triggers.region} --filter "Name=tag:aws:eks:cluster-name,Values=${self.triggers.filmdrop_analytics_cluster_name}" --query 'SecurityGroups[*].[GroupId]' --output text`
aws ec2 revoke-security-group-ingress --group-id $SUBNET_ID --cidr ${self.triggers.vpc_cidr_range} --protocol all 2> /dev/null

echo "Adding security group rule for vpc cidr range ..."
SUBNET_ID=`aws ec2 describe-security-groups --region ${self.triggers.region} --filter "Name=tag:aws:eks:cluster-name,Values=${self.triggers.filmdrop_analytics_cluster_name}" --query 'SecurityGroups[*].[GroupId]' --output text`
aws ec2 authorize-security-group-ingress --group-id $SUBNET_ID --cidr ${self.triggers.vpc_cidr_range} --protocol all

EOF

  }

  provisioner "local-exec" {
    when          = destroy
    command       = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.region}
export AWS_REGION=${self.triggers.region}

echo "Deleting SG rule on destroy ..."
SUBNET_ID=`aws ec2 describe-security-groups --region ${self.triggers.region} --filter "Name=tag:aws:eks:cluster-name,Values=${self.triggers.filmdrop_analytics_cluster_name}" --query 'SecurityGroups[*].[GroupId]' --output text`
aws ec2 revoke-security-group-ingress --group-id $SUBNET_ID --cidr ${self.triggers.vpc_cidr_range} --protocol all 2> /dev/null

EOF
  }


  depends_on = [
    aws_kms_key.analytics_filmdrop_kms_key,
    data.template_file.eksctl_filmdrop,
    data.template_file.kubectl_spec_filmdrop,
    data.template_file.daskhub_helm_filmdrop,
    data.template_file.kubectl_filmdrop_storageclass,
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
    null_resource.create_eks_cluster,
    null_resource.create_kubectl_autoscaler,
    null_resource.create_storage_class,
    null_resource.create_dask_helm
  ]
}

resource "null_resource" "add_jupyterhub_domain" {
  triggers = {
    region                          = data.aws_region.current.name
    account                         = data.aws_caller_identity.current.account_id
    filmdrop_analytics_cluster_name = var.kubernetes_cluster_name
    vpc_cidr_range                  = var.vpc_cidr_range
    new_helm_daskhub                = null_resource.create_dask_helm.id
    new_eks_cluster                 = null_resource.create_eks_cluster.id
    new_kubectl_autoscaler          = null_resource.create_kubectl_autoscaler.id
    new_storage_class               = null_resource.create_storage_class.id
    new_vpc_sg                      = null_resource.authorize_vpc_sg.id
    zone_id                         = var.zone_id
    domain_alias                    = var.domain_alias
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.region}
export AWS_REGION=${self.triggers.region}

sleep 1m
aws eks update-kubeconfig --name ${self.triggers.filmdrop_analytics_cluster_name} --region ${self.triggers.region}
export JUPYTER_DNS=`kubectl get svc proxy-public -o json | jq -r .status.loadBalancer.ingress[].hostname`
echo "Jupyter ELB DNS: $JUPYTER_DNS"
aws route53 change-resource-record-sets --hosted-zone-id ${self.triggers.zone_id} --change-batch '{"Changes": [ { "Action": "UPSERT", "ResourceRecordSet": { "Name": "${self.triggers.domain_alias}", "Type": "CNAME", "TTL": 300, "ResourceRecords": [ { "Value": "'"$JUPYTER_DNS"'" } ] } } ] }'


EOF

  }


  depends_on = [
    aws_kms_key.analytics_filmdrop_kms_key,
    data.template_file.eksctl_filmdrop,
    data.template_file.kubectl_spec_filmdrop,
    data.template_file.daskhub_helm_filmdrop,
    data.template_file.kubectl_filmdrop_storageclass,
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
    null_resource.create_eks_cluster,
    null_resource.create_kubectl_autoscaler,
    null_resource.create_storage_class,
    null_resource.create_dask_helm,
    null_resource.authorize_vpc_sg
  ]
}

module "daskhub_docker_ecr" {
  source = "./docker-images"

  vpc_id              = var.vpc_id
  private_subnet_ids  = var.vpc_private_subnet_ids
  security_group_ids  = var.vpc_security_group_ids
}

resource random_id suffix {
  byte_length = 8
}

resource "aws_s3_bucket" "jupyter_dask_source_config" {
  bucket = "jupyter-config-${random_id.suffix.hex}"
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
  etag   = md5(data.template_file.eksctl_filmdrop.rendered)
  depends_on = [
    data.template_file.eksctl_filmdrop,
    local_file.rendered_eksctl_filmdrop
  ]
}

resource "aws_s3_object" "jupyter_dask_source_config_spec" {
  bucket = aws_s3_bucket.jupyter_dask_source_config.id
  key    = "spec.yaml"
  source = "${path.module}/spec.yaml"
  etag   = md5(data.template_file.kubectl_spec_filmdrop.rendered)
  depends_on = [
    data.template_file.kubectl_spec_filmdrop,
    local_file.rendered_kubectl_spec_filmdrop
  ]
}

resource "aws_s3_object" "jupyter_dask_source_config_daskhub" {
  bucket = aws_s3_bucket.jupyter_dask_source_config.id
  key    = "daskhub.yaml"
  source = "${path.module}/daskhub.yaml"
  etag   = md5(data.template_file.daskhub_helm_filmdrop.rendered)
  depends_on = [
    data.template_file.daskhub_helm_filmdrop,
    local_file.rendered_daskhub_helm_filmdrop
  ]
}

resource "aws_s3_object" "jupyter_dask_source_config_storageclass" {
  bucket = aws_s3_bucket.jupyter_dask_source_config.id
  key    = "storageclass.yaml"
  source = "${path.module}/storageclass.yaml"
  etag   = md5(data.template_file.kubectl_filmdrop_storageclass.rendered)
  depends_on = [
    data.template_file.kubectl_filmdrop_storageclass,
    local_file.rendered_kubectl_filmdrop_storageclass
  ]
}

resource "aws_kms_key" "analytics_filmdrop_kms_key" {
  enable_key_rotation = true
}

resource "local_file" "rendered_eksctl_filmdrop" {
  depends_on = [
    data.template_file.eksctl_filmdrop
  ]
  content  = data.template_file.eksctl_filmdrop.rendered
  filename = "${path.module}/cluster.yaml"
}

resource "local_file" "rendered_daskhub_helm_filmdrop" {
  depends_on = [
    data.template_file.daskhub_helm_filmdrop
  ]
  content  = data.template_file.daskhub_helm_filmdrop.rendered
  filename = "${path.module}/daskhub.yaml"
}

resource "local_file" "rendered_kubectl_filmdrop_storageclass" {
  depends_on = [
    data.template_file.kubectl_filmdrop_storageclass
  ]
  content  = data.template_file.kubectl_filmdrop_storageclass.rendered
  filename = "${path.module}/storageclass.yaml"
}

resource "local_file" "rendered_kubectl_spec_filmdrop" {
  depends_on = [
    data.template_file.kubectl_spec_filmdrop
  ]
  content  = data.template_file.kubectl_spec_filmdrop.rendered
  filename = "${path.module}/spec.yaml"
}
