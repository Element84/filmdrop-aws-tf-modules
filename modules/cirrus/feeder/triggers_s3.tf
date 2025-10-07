# Create an S3 bucket for each trigger
resource "aws_s3_bucket" "event_bucket" {
  for_each = {
    for trigger in coalesce(var.feeder_config.triggers_s3, []) : trigger.bucket_name_suffix => trigger
  }

  bucket        = "${local.name_main}-${each.key}"
  force_destroy = true
}

# Create a notification on each S3 bucket to send events to the feeder SQS queue
resource "aws_s3_bucket_notification" "bucket_notification" {
  for_each = {
    for trigger in coalesce(var.feeder_config.triggers_s3, []) : trigger.bucket_name_suffix => trigger
  }

  bucket = aws_s3_bucket.event_bucket[each.key].id

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
