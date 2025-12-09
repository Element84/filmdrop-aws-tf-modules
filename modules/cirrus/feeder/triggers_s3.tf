# Create a notification on each S3 bucket to send events to the feeder SQS queue
resource "aws_s3_bucket_notification" "bucket_notification_trigger" {
  for_each = {
    for trigger in coalesce(var.feeder_config.triggers_s3, []) : trigger.bucket_arn => trigger
  }

  bucket = each.value.bucket_name

  queue {
    queue_arn     = aws_sqs_queue.feeder_queue.arn
    events        = each.value.events
    filter_prefix = each.value.filter_prefix
    filter_suffix = each.value.filter_suffix
  }

  depends_on = [
    aws_sqs_queue_policy.sqs_policy
  ]
}
