moved {
  from = module.functions
  to   = module.builtin_functions
}

module "builtin_functions" {
  source = "./builtin-functions"

  vpc_id                                           = var.vpc_id
  vpc_subnet_ids                                   = var.vpc_subnet_ids
  vpc_security_group_ids                           = var.vpc_security_group_ids
  resource_prefix                                  = var.resource_prefix
  cirrus_log_level                                 = var.cirrus_log_level
  cirrus_data_bucket                               = module.base.cirrus_data_bucket
  cirrus_payload_bucket                            = module.base.cirrus_payload_bucket
  cirrus_lambda_version                            = var.cirrus_lambda_version
  cirrus_lambda_zip_filepath                       = var.cirrus_lambda_zip_filepath
  cirrus_api_rest_type                             = var.cirrus_api_rest_type
  cirrus_private_api_additional_security_group_ids = var.cirrus_private_api_additional_security_group_ids
  cirrus_api_lambda_timeout                        = var.cirrus_api_lambda_timeout
  cirrus_api_lambda_memory                         = var.cirrus_api_lambda_memory
  cirrus_process_lambda_timeout                    = var.cirrus_process_lambda_timeout
  cirrus_process_lambda_memory                     = var.cirrus_process_lambda_memory
  cirrus_process_lambda_reserved_concurrency       = var.cirrus_process_lambda_reserved_concurrency
  cirrus_update_state_lambda_timeout               = var.cirrus_update_state_lambda_timeout
  cirrus_update_state_lambda_memory                = var.cirrus_update_state_lambda_memory
  cirrus_pre_batch_lambda_timeout                  = var.cirrus_pre_batch_lambda_timeout
  cirrus_pre_batch_lambda_memory                   = var.cirrus_pre_batch_lambda_memory
  cirrus_post_batch_lambda_timeout                 = var.cirrus_post_batch_lambda_timeout
  cirrus_post_batch_lambda_memory                  = var.cirrus_post_batch_lambda_memory
  cirrus_state_dynamodb_table_name                 = module.base.cirrus_state_dynamodb_table_name
  cirrus_state_dynamodb_table_arn                  = module.base.cirrus_state_dynamodb_table_arn
  cirrus_state_event_timestreamwrite_database_name = module.base.cirrus_state_event_timestreamwrite_database_name
  cirrus_state_event_timestreamwrite_table_name    = module.base.cirrus_state_event_timestreamwrite_table_name
  cirrus_state_event_timestreamwrite_table_arn     = module.base.cirrus_state_event_timestreamwrite_table_arn
  cirrus_workflow_event_sns_topic_arn              = module.base.cirrus_workflow_event_sns_topic_arn
  cirrus_publish_sns_topic_arn                     = module.base.cirrus_publish_sns_topic_arn
  cirrus_process_sqs_queue_arn                     = module.base.cirrus_process_sqs_queue_arn
  cirrus_process_sqs_queue_url                     = module.base.cirrus_process_sqs_queue_url
  cirrus_update_state_dead_letter_sqs_queue_arn    = module.base.cirrus_update_state_dead_letter_sqs_queue_arn
  warning_sns_topic_arn                            = var.warning_sns_topic_arn
  critical_sns_topic_arn                           = var.critical_sns_topic_arn
  deploy_alarms                                    = var.deploy_alarms
  domain_alias                                     = var.domain_alias
  private_certificate_arn                          = var.private_certificate_arn
}
