#Add SNS subscriptions to the topics
resource "aws_sns_topic_subscription" "sns_topics_subscriptions" {
  for_each = var.sns_topics_subscriptions_map

  topic_arn = var.sns_topic_arn
  protocol  = each.value.subscription_protocol
  endpoint  = each.value.subscription_endpoint
}
