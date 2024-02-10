module "vpc_infra" {
  count  = var.deploy_vpc ? 1 : 0
  source = "../../../modules/base_infra/vpc_infra"

  project_name                 = var.project_name
  environment                  = var.environment
  vpc_cidr                     = var.vpc_cidr
  private_subnets_az_to_id_map = var.private_subnets_az_to_id_map
  public_subnets_az_to_id_map  = var.public_subnets_az_to_id_map
  archive_log_bucket_name      = var.archive_log_bucket_name
}

module "vpc_search" {
  count  = !var.deploy_vpc && var.deploy_vpc_search ? 1 : 0
  source = "../vpc_search"
}
