moved {
  from = module.base-builtins
  to   = module.base
}

module "base" {
  source = "./base"

  cirrus_prefix                                             = local.cirrus_prefix
  cirrus_process_sqs_timeout                                = var.cirrus_process_sqs_timeout
  cirrus_process_sqs_max_receive_count                      = var.cirrus_process_sqs_max_receive_count
  cirrus_timestream_magnetic_store_retention_period_in_days = var.cirrus_timestream_magnetic_store_retention_period_in_days
  cirrus_timestream_memory_store_retention_period_in_hours  = var.cirrus_timestream_memory_store_retention_period_in_hours
  cirrus_data_bucket                                        = var.cirrus_data_bucket
  cirrus_payload_bucket                                     = var.cirrus_payload_bucket
  warning_sns_topic_arn                                     = var.warning_sns_topic_arn
  deploy_alarms                                             = var.deploy_alarms
}
