output "vpc_id" {
  value = module.base_infra.vpc_id
}

output "vpc_cidr" {
  value = module.base_infra.vpc_cidr
}

output "private_subnet_ids" {
  value = module.base_infra.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.base_infra.public_subnet_ids
}

output "security_group_id" {
  value = module.base_infra.security_group_id
}

output "private_avaliability_zones" {
  value = module.base_infra.private_avaliability_zones
}

output "public_avaliability_zones" {
  value = module.base_infra.public_avaliability_zones
}

output "s3_logs_archive_bucket" {
  value = module.base_infra.s3_logs_archive_bucket
}

output "s3_access_log_bucket" {
  value = module.base_infra.s3_access_log_bucket
}

output "analytics_url" {
  value = var.deploy_analytics ? module.analytics[0].analytics_url : ""
}

output "stac_url" {
  value = var.deploy_stac_server ? module.stac-server[0].stac_url : ""
}

output "stac_opensearch_domain_name" {
  value = var.deploy_stac_server ? module.stac-server[0].stac_opensearch_domain_name : ""
}

output "stac_opensearch_endpoint" {
  value = var.deploy_stac_server ? module.stac-server[0].stac_opensearch_endpoint : ""
}

output "console_ui_url" {
  value = var.deploy_console_ui ? module.console-ui[0].console_ui_url : ""
}

output "cirrus_dashboard_url" {
  value = var.deploy_cirrus_dashboard ? module.cirrus-dashboard[0].cirrus_dashboard_url : ""
}

output "titiler_url" {
  value = var.deploy_titiler ? module.titiler[0].titiler_url : ""
}

output "stac_ingest_queue_arn" {
  value = var.deploy_stac_server ? module.stac-server[0].stac_ingest_queue_arn : ""
}

output "stac_ingest_queue_url" {
  value = var.deploy_stac_server ? module.stac-server[0].stac_ingest_queue_url : ""
}

output "cirrus_publish_sns_topic_arn" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_publish_sns_topic_arn : ""
}

output "cirrus_workflow_event_sns_topic_arn" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_workflow_event_sns_topic_arn : ""
}

output "cirrus_process_sqs_queue_arn" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_process_sqs_queue_arn : ""
}

output "cirrus_process_sqs_queue_url" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_process_sqs_queue_url : ""
}

output "cirrus_process_dead_letter_sqs_queue_arn" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_process_dead_letter_sqs_queue_arn : ""
}

output "cirrus_process_dead_letter_sqs_queue_url" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_process_dead_letter_sqs_queue_url : ""
}

output "cirrus_update_state_dead_letter_sqs_queue_arn" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_update_state_dead_letter_sqs_queue_arn : ""
}

output "cirrus_update_state_dead_letter_sqs_queue_url" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_update_state_dead_letter_sqs_queue_url : ""
}

output "cirrus_state_dynamodb_table_name" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_state_dynamodb_table_name : ""
}

output "cirrus_state_dynamodb_table_arn" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_state_dynamodb_table_arn : ""
}

output "cirrus_state_event_timestreamwrite_database_name" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_state_event_timestreamwrite_database_name : ""
}

output "cirrus_state_event_timestreamwrite_table_name" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_state_event_timestreamwrite_table_name : ""
}

output "cirrus_state_event_timestreamwrite_table_arn" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_state_event_timestreamwrite_table_arn : ""
}

output "cirrus_instance_role_arn" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_instance_role_arn : ""
}

output "cirrus_instance_profile_name" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_instance_profile_name : ""
}

output "cirrus_instance_profile_arn" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_instance_profile_arn : ""
}

output "cirrus_lambda_version" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_lambda_version : ""
}

output "cirrus_data_bucket" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_data_bucket : ""
}

output "cirrus_payload_bucket" {
  value = var.deploy_cirrus ? module.cirrus[0].cirrus_payload_bucket : ""
}

output "cirrus_workflow_state_machine_arns" {
  description = <<-DESCRIPTION
  Map of Cirrus Workflow names to their State Machine ARN.
  DESCRIPTION

  value = var.deploy_cirrus ? module.cirrus[0].cirrus_workflow_state_machine_arns : null
}

output "cirrus_workflow_state_machine_role_arns" {
  description = <<-DESCRIPTION
  Map of Cirrus Workflow names to their State Machine's IAM role ARN.
  DESCRIPTION

  value = var.deploy_cirrus ? module.cirrus[0].cirrus_workflow_state_machine_role_arns : null
}

output "cirrus_task_role_arns" {
  description = <<-DESCRIPTION
  Map of cirrus task names to their IAM role ARN.
  DESCRIPTION

  value = var.deploy_cirrus ? module.cirrus[0].cirrus_task_role_arns : null
}

output "cirrus_task_resolved_ecr_image_digests" {
  description = <<-DESCRIPTION
  Map of cirrus task names to their resolved ECR image digests (if `resolve_ecr_tag_to_digest` was set for the task + task type).
  DESCRIPTION

  value = var.deploy_cirrus ? module.cirrus[0].cirrus_task_resolved_ecr_image_digests : null
}

output "cirrus_task_batch_compute_template_variables" {
  description = <<-DESCRIPTION
  Map of Cirrus task batch compute names to their resolved template variables (static and SSM combined).
  This shows the final variable values that were used during YAML templating.
  DESCRIPTION

  value = var.deploy_cirrus ? module.cirrus[0].cirrus_task_batch_compute_template_variables : null
}

output "cirrus_task_template_variables" {
  description = <<-DESCRIPTION
  Map of Cirrus task names to their resolved template variables (static and SSM combined).
  This shows the final variable values that were used during YAML templating.
  DESCRIPTION

  value = var.deploy_cirrus ? module.cirrus[0].cirrus_task_template_variables : null
}

output "cirrus_workflow_template_variables" {
  description = <<-DESCRIPTION
  Map of Cirrus workflow names to their resolved template variables (static and SSM combined).
  This shows the final variable values that were used during YAML templating.
  DESCRIPTION

  value = var.deploy_cirrus ? module.cirrus[0].cirrus_workflow_template_variables : null
}

output "warning_sns_topic_arn" {
  value = module.base_infra.warning_sns_topic_arn
}

output "critical_sns_topic_arn" {
  value = module.base_infra.critical_sns_topic_arn
}

output "stac_server_ingest_sns_topic_arn" {
  value = var.deploy_stac_server ? module.stac-server[0].stac_server_ingest_sns_topic_arn : ""
}

output "stac_server_post_ingest_sns_topic_arn" {
  value = var.deploy_stac_server ? module.stac-server[0].stac_server_post_ingest_sns_topic_arn : ""
}

output "stac_server_lambda_iam_role_arn" {
  value = var.deploy_stac_server ? module.stac-server[0].stac_server_lambda_iam_role_arn : ""
}


output "stac_server_api_gateway_id" {
  value = var.deploy_stac_server ? module.stac-server[0].stac_server_api_gateway_id : ""
}

output "stac_server_ingest_lambda_name" {
  value = var.deploy_stac_server ? module.stac-server[0].stac_server_ingest_lambda_name : ""
}

output "stac_server_ingest_lambda_arn" {
  value = var.deploy_stac_server ? module.stac-server[0].stac_server_ingest_lambda_arn : ""
}

output "stac_server_api_lambda_name" {
  value = var.deploy_stac_server ? module.stac-server[0].stac_server_api_lambda_name : ""
}

output "stac_server_api_lambda_arn" {
  value = var.deploy_stac_server ? module.stac-server[0].stac_server_api_lambda_arn : ""
}


output "console_ui_bucket_name" {
  value = var.deploy_console_ui ? module.console-ui[0].console_ui_bucket_name : ""
}

output "cirrus_dashboard_bucket_name" {
  value = var.deploy_cirrus_dashboard ? module.cirrus-dashboard[0].cirrus_dashboard_bucket_name : ""
}
