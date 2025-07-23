moved {
  from = module.base-builtins
  to   = module.base
}

module "base" {
  source = "./base"

  resource_prefix                                           = var.resource_prefix
  cirrus_process_sqs_timeout                                = var.cirrus_process_sqs_timeout
  cirrus_process_sqs_max_receive_count                      = var.cirrus_process_sqs_max_receive_count
  cirrus_process_sqs_cross_account_sender_arns              = var.cirrus_process_sqs_cross_account_sender_arns
  cirrus_timestream_magnetic_store_retention_period_in_days = var.cirrus_timestream_magnetic_store_retention_period_in_days
  cirrus_timestream_memory_store_retention_period_in_hours  = var.cirrus_timestream_memory_store_retention_period_in_hours
  cirrus_data_bucket                                        = var.cirrus_data_bucket
  cirrus_payload_bucket                                     = var.cirrus_payload_bucket
  warning_sns_topic_arn                                     = var.warning_sns_topic_arn
  deploy_alarms                                             = var.deploy_alarms
}
