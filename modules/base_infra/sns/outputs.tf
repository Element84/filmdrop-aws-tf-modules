output "sns_topic_arns" {
  description = "SNS topic ARNS"
  value = {
    for k, v in aws_sns_topic.sns_topics : k => v.arn
  }
}