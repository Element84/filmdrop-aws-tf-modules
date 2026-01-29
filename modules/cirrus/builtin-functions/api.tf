module "cirrus_api" {
  source = "./api"
  count  = var.deploy_api && var.cirrus_api_lambda_settings != null ? 1 : 0

  vpc_id                       = var.vpc_id
  vpc_subnet_ids               = var.vpc_subnet_ids
  vpc_security_group_ids       = var.vpc_security_group_ids
  resource_prefix              = var.resource_prefix
  cirrus_log_level             = var.cirrus_log_level
  cirrus_data_bucket           = var.cirrus_data_bucket
  cirrus_payload_bucket        = var.cirrus_payload_bucket
  cirrus_lambda_version        = var.cirrus_lambda_version
  cirrus_lambda_zip_filepath   = var.cirrus_lambda_zip_filepath
  cirrus_lambda_pyversion      = var.cirrus_lambda_pyversion
  cirrus_api_stage             = var.cirrus_api_stage
  cirrus_api_stage_description = var.cirrus_api_stage_description

  cirrus_api_lambda_settings = var.cirrus_api_lambda_settings

  cirrus_private_api_additional_security_group_ids = var.cirrus_private_api_additional_security_group_ids

  cirrus_state_dynamodb_table_name                 = var.cirrus_state_dynamodb_table_name
  cirrus_state_dynamodb_table_arn                  = var.cirrus_state_dynamodb_table_arn
  cirrus_state_event_timestreamwrite_database_name = var.cirrus_state_event_timestreamwrite_database_name
  cirrus_state_event_timestreamwrite_table_name    = var.cirrus_state_event_timestreamwrite_table_name
  cirrus_state_event_timestreamwrite_table_arn     = var.cirrus_state_event_timestreamwrite_table_arn
  workflow_metrics_cloudwatch_enabled              = var.workflow_metrics_cloudwatch_enabled
  workflow_metrics_cloudwatch_namespace            = var.workflow_metrics_cloudwatch_enabled ? var.workflow_metrics_cloudwatch_namespace : ""
  workflow_metrics_cloudwatch_read_policy_arn      = var.workflow_metrics_cloudwatch_enabled ? var.workflow_metrics_cloudwatch_read_policy_arn : ""
  workflow_metrics_timestream_enabled              = var.workflow_metrics_timestream_enabled
  warning_sns_topic_arn                            = var.warning_sns_topic_arn
  critical_sns_topic_arn                           = var.critical_sns_topic_arn
  deploy_alarms                                    = var.deploy_alarms
  domain_alias                                     = var.domain_alias
  private_certificate_arn                          = var.private_certificate_arn
  cirrus_lambda_download_trigger                   = var.cirrus_lambda_zip_filepath == null ? null_resource.get_cirrus_lambda[0].id : null
}