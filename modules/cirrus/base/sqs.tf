resource "aws_sqs_queue" "cirrus_process_sqs_queue" {
  name = "${var.cirrus_prefix}-process"
  visibility_timeout_seconds = var.cirrus_process_sqs_timeout

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.cirrus_process_dead_letter_sqs_queue.arn
    maxReceiveCount     = var.cirrus_process_sqs_max_receive_count
  })
}

resource "aws_sqs_queue" "cirrus_process_dead_letter_sqs_queue" {
  name = "${var.cirrus_prefix}-process-dead-letter"
}

resource "aws_sqs_queue" "cirrus_update_state_dead_letter_sqs_queue" {
  name = "${var.cirrus_prefix}-update-state-dead-letter"
}
