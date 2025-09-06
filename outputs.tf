output "vpc_id" {
  value = module.filmdrop.vpc_id
}

output "vpc_cidr" {
  value = module.filmdrop.vpc_cidr
}

output "private_subnet_ids" {
  value = module.filmdrop.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.filmdrop.public_subnet_ids
}

output "security_group_id" {
  value = module.filmdrop.security_group_id
}

output "private_avaliability_zones" {
  value = module.filmdrop.private_avaliability_zones
}

output "public_avaliability_zones" {
  value = module.filmdrop.public_avaliability_zones
}

output "s3_logs_archive_bucket" {
  value = module.filmdrop.s3_logs_archive_bucket
}

output "s3_access_log_bucket" {
  value = module.filmdrop.s3_access_log_bucket
}

output "analytics_url" {
  value = module.filmdrop.analytics_url
}

output "stac_url" {
  value = module.filmdrop.stac_url
}

output "stac_opensearch_domain_name" {
  value = module.filmdrop.stac_opensearch_domain_name
}

output "stac_opensearch_endpoint" {
  value = module.filmdrop.stac_opensearch_endpoint
}

output "console_ui_url" {
  value = module.filmdrop.console_ui_url
}

output "cirrus_dashboard_url" {
  value = module.filmdrop.cirrus_dashboard_url
}

output "titiler_url" {
  value = module.filmdrop.titiler_url
}

output "stac_ingest_queue_arn" {
  value = module.filmdrop.stac_ingest_queue_arn
}

output "stac_ingest_queue_url" {
  value = module.filmdrop.stac_ingest_queue_url
}

output "cirrus_publish_sns_topic_arn" {
  value = module.filmdrop.cirrus_publish_sns_topic_arn
}

output "cirrus_workflow_event_sns_topic_arn" {
  value = module.filmdrop.cirrus_workflow_event_sns_topic_arn
}

output "cirrus_process_sqs_queue_arn" {
  value = module.filmdrop.cirrus_process_sqs_queue_arn
}

output "cirrus_process_sqs_queue_url" {
  value = module.filmdrop.cirrus_process_sqs_queue_url
}

output "cirrus_process_dead_letter_sqs_queue_arn" {
  value = module.filmdrop.cirrus_process_dead_letter_sqs_queue_arn
}

output "cirrus_process_dead_letter_sqs_queue_url" {
  value = module.filmdrop.cirrus_process_dead_letter_sqs_queue_url
}

output "cirrus_update_state_dead_letter_sqs_queue_arn" {
  value = module.filmdrop.cirrus_update_state_dead_letter_sqs_queue_arn
}

output "cirrus_update_state_dead_letter_sqs_queue_url" {
  value = module.filmdrop.cirrus_update_state_dead_letter_sqs_queue_url
}

output "cirrus_state_dynamodb_table_name" {
  value = module.filmdrop.cirrus_state_dynamodb_table_name
}

output "cirrus_state_dynamodb_table_arn" {
  value = module.filmdrop.cirrus_state_dynamodb_table_arn
}

output "cirrus_state_event_timestreamwrite_database_name" {
  value = module.filmdrop.cirrus_state_event_timestreamwrite_database_name
}

output "cirrus_state_event_timestreamwrite_table_name" {
  value = module.filmdrop.cirrus_state_event_timestreamwrite_table_name
}

output "cirrus_state_event_timestreamwrite_table_arn" {
  value = module.filmdrop.cirrus_state_event_timestreamwrite_table_arn
}

output "cirrus_instance_role_arn" {
  value = module.filmdrop.cirrus_instance_role_arn
}

output "cirrus_instance_profile_name" {
  value = module.filmdrop.cirrus_instance_profile_name
}

output "cirrus_instance_profile_arn" {
  value = module.filmdrop.cirrus_instance_profile_arn
}

output "cirrus_lambda_version" {
  value = module.filmdrop.cirrus_lambda_version
}

output "cirrus_data_bucket" {
  value = module.filmdrop.cirrus_data_bucket
}

output "cirrus_payload_bucket" {
  value = module.filmdrop.cirrus_payload_bucket
}

output "cirrus_workflow_state_machine_arns" {
  description = <<-DESCRIPTION
  Map of Cirrus Workflow names to their State Machine ARN.
  DESCRIPTION

  value = module.filmdrop.cirrus_workflow_state_machine_arns
}

output "cirrus_workflow_state_machine_role_arns" {
  description = <<-DESCRIPTION
  Map of Cirrus Workflow names to their State Machine's IAM role ARN.
  DESCRIPTION

  value = module.filmdrop.cirrus_workflow_state_machine_role_arns
}

output "cirrus_task_role_arns" {
  description = <<-DESCRIPTION
  Map of cirrus task names to their IAM role ARN.
  DESCRIPTION

  value = module.filmdrop.cirrus_task_role_arns
}

output "cirrus_task_resolved_ecr_image_digests" {
  description = <<-DESCRIPTION
  Map of cirrus task names to their resolved ECR image digests (if `resolve_ecr_tag_to_digest` was set for the task + task type).
  DESCRIPTION

  value = module.filmdrop.cirrus_task_resolved_ecr_image_digests
}

output "cirrus_task_batch_compute_template_variables" {
  description = <<-DESCRIPTION
  Map of Cirrus task batch compute names to their resolved template variables (static and SSM combined).
  This shows the final variable values that were used during YAML templating.
  DESCRIPTION

  value = module.filmdrop.cirrus_task_batch_compute_template_variables
}

output "cirrus_task_template_variables" {
  description = <<-DESCRIPTION
  Map of Cirrus task names to their resolved template variables (static and SSM combined).
  This shows the final variable values that were used during YAML templating.
  DESCRIPTION

  value = module.filmdrop.cirrus_task_template_variables
}

output "cirrus_workflow_template_variables" {
  description = <<-DESCRIPTION
  Map of Cirrus workflow names to their resolved template variables (static and SSM combined).
  This shows the final variable values that were used during YAML templating.
  DESCRIPTION

  value = module.filmdrop.cirrus_workflow_template_variables
}

output "warning_sns_topic_arn" {
  value = module.filmdrop.warning_sns_topic_arn
}

output "critical_sns_topic_arn" {
  value = module.filmdrop.critical_sns_topic_arn
}

output "stac_server_ingest_sns_topic_arn" {
  value = module.filmdrop.stac_server_ingest_sns_topic_arn
}

output "stac_server_post_ingest_sns_topic_arn" {
  value = module.filmdrop.stac_server_post_ingest_sns_topic_arn
}

output "stac_server_lambda_iam_role_arn" {
  value = module.filmdrop.stac_server_lambda_iam_role_arn
}

output "stac_server_api_gateway_id" {
  value = module.filmdrop.stac_server_api_gateway_id
}

output "stac_server_ingest_lambda_name" {
  value = module.filmdrop.stac_server_ingest_lambda_name
}

output "stac_server_ingest_lambda_arn" {
  value = module.filmdrop.stac_server_ingest_lambda_arn
}

output "stac_server_api_lambda_name" {
  value = module.filmdrop.stac_server_api_lambda_name
}

output "stac_server_api_lambda_arn" {
  value = module.filmdrop.stac_server_api_lambda_arn
}


output "console_ui_bucket_name" {
  value = module.filmdrop.console_ui_bucket_name
}

output "cirrus_dashboard_bucket_name" {
  value = module.filmdrop.cirrus_dashboard_bucket_name
}
