module "functions" {
  source = "./functions"

  vpc_subnet_ids                                            = var.vpc_subnet_ids
  vpc_security_group_ids                                    = var.vpc_security_group_ids
  cirrus_prefix                                             = local.cirrus_prefix
  cirrus_log_level                                          = var.cirrus_log_level
  cirrus_data_bucket                                        = var.cirrus_data_bucket
  cirrus_payload_bucket                                     = var.cirrus_payload_bucket
  cirrus_api_lambda_timeout                                 = var.cirrus_api_lambda_timeout
  cirrus_api_lambda_memory                                  = var.cirrus_api_lambda_memory
  cirrus_state_dynamodb_table_name                          = module.base-builtins.cirrus_state_dynamodb_table_name
  cirrus_state_dynamodb_table_arn                           = module.base-builtins.cirrus_state_dynamodb_table_arn
  cirrus_state_event_timestreamwrite_database_name          = module.base-builtins.cirrus_state_event_timestreamwrite_database_name
  cirrus_state_event_timestreamwrite_table_name             = module.base-builtins.cirrus_state_event_timestreamwrite_table_name
  cirrus_state_event_timestreamwrite_table_arn              = module.base-builtins.cirrus_state_event_timestreamwrite_table_arn
}
