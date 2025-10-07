# Create an SNS topic for each trigger
resource "aws_sns_topic" "event_topic" {
  for_each = {
    for trigger in coalesce(var.feeder_config.triggers_sns, []) : trigger.topic_name_suffix => trigger
  }

  name = "${local.name_main}-${each.key}"
}

# Create a subscription on each SNS topic to send messages to the feeder SQS queue
resource "aws_sns_topic_subscription" "sqs_subscription" {
  for_each = {
    for trigger in coalesce(var.feeder_config.triggers_sns, []) : trigger.topic_name_suffix => trigger
  }

  topic_arn = aws_sns_topic.event_topic[each.key].arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.feeder_queue.arn

  delivery_policy      = each.value.delivery_policy != null ? jsonencode(yamldecode(each.value.delivery_policy)) : null
  filter_policy        = each.value.filter_policy != null ? jsonencode(yamldecode(each.value.filter_policy)) : null
  filter_policy_scope  = each.value.filter_policy_scope
  raw_message_delivery = each.value.raw_message_delivery
}
