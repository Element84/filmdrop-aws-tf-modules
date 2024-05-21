output "cirrus_publish_sns_topic_arn" {
  value = module.cirrus.cirrus_publish_sns_topic_arn
}

output "cirrus_workflow_event_sns_topic_arn" {
  value = module.cirrus.cirrus_workflow_event_sns_topic_arn
}

output "cirrus_failed_sns_topic_arn" {
  value = module.cirrus.cirrus_failed_sns_topic_arn
}

output "cirrus_process_sqs_queue_arn" {
  value = module.cirrus.cirrus_process_sqs_queue_arn
}

output "cirrus_process_dead_letter_sqs_queue_arn" {
  value = module.cirrus.cirrus_process_dead_letter_sqs_queue_arn
}

output "cirrus_update_state_dead_letter_sqs_queue_arn" {
  value = module.cirrus.cirrus_update_state_dead_letter_sqs_queue_arn
}

output "cirrus_state_dynamodb_table_name" {
  value = module.cirrus.cirrus_state_dynamodb_table_name
}

output "cirrus_state_event_timestreamwrite_database_name" {
  value = module.cirrus.cirrus_state_event_timestreamwrite_database_name
}

output "cirrus_state_event_timestreamwrite_table_name" {
  value = module.cirrus.cirrus_state_event_timestreamwrite_table_name
}

output "cirrus_batch_role_arn" {
  value = module.cirrus.cirrus_batch_role_arn
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

output "cirrus_ec2_spot_role_arn" {
  value = module.cirrus.cirrus_ec2_spot_role_arn
}

output "cirrus_data_bucket" {
  value = module.cirrus.cirrus_data_bucket
}

output "cirrus_payload_bucket" {
  value = module.cirrus.cirrus_payload_bucket
}
