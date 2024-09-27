resource "aws_sns_topic" "sns_topics" {
  for_each = var.sns_topics_map

  name = each.key
}

resource "aws_sns_topic_policy" "sns_topic_polcies" {
  for_each = var.sns_topics_map

  arn    = aws_sns_topic.sns_topics[each.key].arn
  policy = templatefile(lookup(each.value, "policy_file_path_name", local.default_sns_policy_file_path_name), { resource = aws_sns_topic.sns_topics[each.key].arn, account_id = data.aws_caller_identity.current.account_id })

  lifecycle {
    ignore_changes = [
      policy
    ]
  }
}
