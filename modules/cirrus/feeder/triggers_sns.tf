# Create a subscription on each SNS topic to send messages to the feeder queue
resource "aws_sns_topic_subscription" "sqs_subscription" {
  for_each = {
    for trigger in coalesce(var.feeder_config.triggers_sns, []) : trigger.topic_arn => trigger
  }

  topic_arn = each.value.topic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.feeder_queue.arn

  delivery_policy      = each.value.delivery_policy != null ? jsonencode(yamldecode(each.value.delivery_policy)) : null
  filter_policy        = each.value.filter_policy != null ? jsonencode(yamldecode(each.value.filter_policy)) : null
  filter_policy_scope  = each.value.filter_policy_scope
  raw_message_delivery = each.value.raw_message_delivery
}
