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
