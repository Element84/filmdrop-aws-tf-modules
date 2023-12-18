module "admin_creds" {
  source = "./admin"
  count  = var.create_credentials ? 1 : 0

  credentials_name_prefix = var.credentials_name_prefix
}
