output "cirrus_publish_sns_topic_arn" {
  value = module.cirrus.cirrus_publish_sns_topic_arn
}

output "cirrus_workflow_event_sns_topic_arn" {
  value = module.cirrus.cirrus_workflow_event_sns_topic_arn
}

output "cirrus_process_sqs_queue_arn" {
  value = module.cirrus.cirrus_process_sqs_queue_arn
}

output "cirrus_process_sqs_queue_url" {
  value = module.cirrus.cirrus_process_sqs_queue_url
}

output "cirrus_process_dead_letter_sqs_queue_arn" {
  value = module.cirrus.cirrus_process_dead_letter_sqs_queue_arn
}

output "cirrus_process_dead_letter_sqs_queue_url" {
  value = module.cirrus.cirrus_process_dead_letter_sqs_queue_url
}

output "cirrus_update_state_dead_letter_sqs_queue_arn" {
  value = module.cirrus.cirrus_update_state_dead_letter_sqs_queue_arn
}

output "cirrus_update_state_dead_letter_sqs_queue_url" {
  value = module.cirrus.cirrus_update_state_dead_letter_sqs_queue_url
}

output "cirrus_state_dynamodb_table_name" {
  value = module.cirrus.cirrus_state_dynamodb_table_name
}

output "cirrus_state_dynamodb_table_arn" {
  value = module.cirrus.cirrus_state_dynamodb_table_arn
}

output "cirrus_state_event_timestreamwrite_database_name" {
  value = module.cirrus.cirrus_state_event_timestreamwrite_database_name
}

output "cirrus_state_event_timestreamwrite_table_name" {
  value = module.cirrus.cirrus_state_event_timestreamwrite_table_name
}

output "cirrus_state_event_timestreamwrite_table_arn" {
  value = module.cirrus.cirrus_state_event_timestreamwrite_table_arn
}

output "cirrus_instance_role_arn" {
  value = module.cirrus.cirrus_instance_role_arn
}

output "cirrus_instance_profile_name" {
  value = module.cirrus.cirrus_instance_profile_name
}

output "cirrus_instance_profile_arn" {
  value = module.cirrus.cirrus_instance_profile_arn
}

output "cirrus_lambda_version" {
  value = module.cirrus.cirrus_lambda_version
}

output "cirrus_data_bucket" {
  value = module.cirrus.cirrus_data_bucket
}

output "cirrus_payload_bucket" {
  value = module.cirrus.cirrus_payload_bucket
}

output "cirrus_workflow_state_machine_arns" {
  description = <<-DESCRIPTION
  Map of Cirrus Workflow names to their State Machine ARN.
  DESCRIPTION

  value = module.cirrus.cirrus_workflow_state_machine_arns
}

output "cirrus_workflow_state_machine_role_arns" {
  description = <<-DESCRIPTION
  Map of Cirrus Workflow names to their State Machine's IAM role ARN.
  DESCRIPTION

  value = module.cirrus.cirrus_workflow_state_machine_role_arns
}

output "cirrus_task_role_arns" {
  description = <<-DESCRIPTION
  Map of cirrus task names to their IAM role ARN.
  DESCRIPTION

  value = module.cirrus.cirrus_task_role_arns
}

output "cirrus_task_resolved_ecr_image_digests" {
  description = <<-DESCRIPTION
  Map of cirrus task names to their resolved ECR image digests (if `resolve_ecr_tag_to_digest` was set for the task + task type).
  DESCRIPTION

  value = module.cirrus.cirrus_task_resolved_ecr_image_digests
}

output "cirrus_task_batch_compute_template_variables" {
  description = <<-DESCRIPTION
  Map of task batch compute names to their resolved template variables (static and SSM combined).
  This shows the final variable values that were used during YAML templating.
  DESCRIPTION

  value = module.cirrus.cirrus_task_batch_compute_template_variables
}

output "cirrus_task_template_variables" {
  description = <<-DESCRIPTION
  Map of task names to their resolved template variables (static and SSM combined).
  This shows the final variable values that were used during YAML templating.
  DESCRIPTION

  value = module.cirrus.cirrus_task_template_variables
}

output "cirrus_workflow_template_variables" {
  description = <<-DESCRIPTION
  Map of workflow names to their resolved template variables (static and SSM combined).
  This shows the final variable values that were used during YAML templating.
  DESCRIPTION

  value = module.cirrus.cirrus_workflow_template_variables
}
