module "cirrus" {
  source = "../../modules/cirrus"

  # Namespace all cirrus resources via prefix
  resource_prefix = lower(replace("fd-${local.cirrus_env}-cirrus", "_", "-"))

  project_name                                              = var.project_name
  environment                                               = var.environment
  vpc_id                                                    = var.vpc_id
  vpc_subnet_ids                                            = var.private_subnet_ids
  vpc_security_group_ids                                    = [var.security_group_id]
  cirrus_lambda_version                                     = var.cirrus_inputs.lambda_version
  cirrus_lambda_zip_filepath                                = var.cirrus_inputs.lambda_zip_filepath
  cirrus_process_sqs_timeout                                = var.cirrus_inputs.process.sqs_timeout
  cirrus_process_sqs_max_receive_count                      = var.cirrus_inputs.process.sqs_max_receive_count
  cirrus_timestream_magnetic_store_retention_period_in_days = var.cirrus_inputs.state.timestream_magnetic_store_retention_period_in_days
  cirrus_timestream_memory_store_retention_period_in_hours  = var.cirrus_inputs.state.timestream_memory_store_retention_period_in_hours
  cirrus_data_bucket                                        = var.cirrus_inputs.data_bucket
  cirrus_payload_bucket                                     = var.cirrus_inputs.payload_bucket
  cirrus_log_level                                          = var.cirrus_inputs.log_level
  cirrus_api_rest_type                                      = var.cirrus_inputs.api_rest_type
  cirrus_private_api_additional_security_group_ids          = var.cirrus_inputs.private_api_additional_security_group_ids
  cirrus_api_lambda_timeout                                 = var.cirrus_inputs.api_lambda.timeout
  cirrus_api_lambda_memory                                  = var.cirrus_inputs.api_lambda.memory
  cirrus_process_lambda_timeout                             = var.cirrus_inputs.process_lambda.timeout
  cirrus_process_lambda_memory                              = var.cirrus_inputs.process_lambda.memory
  cirrus_process_lambda_reserved_concurrency                = var.cirrus_inputs.process_lambda.reserved_concurrency
  cirrus_update_state_lambda_timeout                        = var.cirrus_inputs.update_state_lambda.timeout
  cirrus_update_state_lambda_memory                         = var.cirrus_inputs.update_state_lambda.memory
  cirrus_pre_batch_lambda_timeout                           = var.cirrus_inputs.pre_batch_lambda.timeout
  cirrus_pre_batch_lambda_memory                            = var.cirrus_inputs.pre_batch_lambda.memory
  cirrus_post_batch_lambda_timeout                          = var.cirrus_inputs.post_batch_lambda.timeout
  cirrus_post_batch_lambda_memory                           = var.cirrus_inputs.post_batch_lambda.memory
  warning_sns_topic_arn                                     = var.warning_sns_topic_arn
  critical_sns_topic_arn                                    = var.critical_sns_topic_arn
  deploy_alarms                                             = var.cirrus_inputs.deploy_alarms
  cirrus_task_batch_compute_definitions_dir                 = var.cirrus_inputs.task_batch_compute_definitions_dir
  cirrus_task_batch_compute_definitions_variables           = var.cirrus_inputs.task_batch_compute_definitions_variables
  cirrus_task_batch_compute_definitions_variables_ssm       = var.cirrus_inputs.task_batch_compute_definitions_variables_ssm
  cirrus_task_definitions_dir                               = var.cirrus_inputs.task_definitions_dir
  cirrus_task_definitions_variables                         = var.cirrus_inputs.task_definitions_variables
  cirrus_task_definitions_variables_ssm                     = var.cirrus_inputs.task_definitions_variables_ssm
  cirrus_workflow_definitions_dir                           = var.cirrus_inputs.workflow_definitions_dir
  cirrus_workflow_definitions_variables                     = var.cirrus_inputs.workflow_definitions_variables
  cirrus_workflow_definitions_variables_ssm                 = var.cirrus_inputs.workflow_definitions_variables_ssm
  cirrus_process_sqs_cross_account_sender_arns              = var.cirrus_inputs.process.sqs_cross_account_sender_arns
  private_certificate_arn                                   = var.cirrus_inputs.private_certificate_arn
  domain_alias                                              = var.cirrus_inputs.domain_alias
}

locals {
  cirrus_env = lower(substr("${var.project_name}-${var.environment}", 0, 12))
}
