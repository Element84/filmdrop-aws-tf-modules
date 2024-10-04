output "cirrus_publish_sns_topic_arn" {
  value = aws_sns_topic.cirrus_publish_sns_topic.arn
}

output "cirrus_workflow_event_sns_topic_arn" {
  value = aws_sns_topic.cirrus_workflow_event_sns_topic.arn
}

output "cirrus_process_sqs_queue_arn" {
  value = aws_sqs_queue.cirrus_process_sqs_queue.arn
}

output "cirrus_process_sqs_queue_url" {
  value = aws_sqs_queue.cirrus_process_sqs_queue.url
}

output "cirrus_process_dead_letter_sqs_queue_arn" {
  value = aws_sqs_queue.cirrus_process_dead_letter_sqs_queue.arn
}

output "cirrus_process_dead_letter_sqs_queue_url" {
  value = aws_sqs_queue.cirrus_process_dead_letter_sqs_queue.url
}

output "cirrus_update_state_dead_letter_sqs_queue_arn" {
  value = aws_sqs_queue.cirrus_update_state_dead_letter_sqs_queue.arn
}

output "cirrus_update_state_dead_letter_sqs_queue_url" {
  value = aws_sqs_queue.cirrus_update_state_dead_letter_sqs_queue.url
}

output "cirrus_state_dynamodb_table_name" {
  value = aws_dynamodb_table.cirrus_state_dynamodb_table.name
}

output "cirrus_state_dynamodb_table_arn" {
  value = aws_dynamodb_table.cirrus_state_dynamodb_table.arn
}

output "cirrus_state_event_timestreamwrite_database_name" {
  value = aws_timestreamwrite_database.cirrus_state_event_timestreamwrite_database.database_name
}

output "cirrus_state_event_timestreamwrite_table_name" {
  value = aws_timestreamwrite_table.cirrus_state_event_timestreamwrite_table.table_name
}

output "cirrus_state_event_timestreamwrite_table_arn" {
  value = aws_timestreamwrite_table.cirrus_state_event_timestreamwrite_table.arn
}

output "cirrus_instance_role_arn" {
  value = aws_iam_role.cirrus_instance_role.arn
}

output "cirrus_instance_profile_name" {
  value = aws_iam_instance_profile.cirrus_instance_profile.name
}

output "cirrus_instance_profile_arn" {
  value = aws_iam_instance_profile.cirrus_instance_profile.arn
}

output "cirrus_data_bucket" {
  value = var.cirrus_data_bucket != "" ? var.cirrus_data_bucket : aws_s3_bucket.cirrus_data_bucket[0].id
}

output "cirrus_payload_bucket" {
  value = var.cirrus_payload_bucket != "" ? var.cirrus_payload_bucket : aws_s3_bucket.cirrus_payload_bucket[0].id
}
