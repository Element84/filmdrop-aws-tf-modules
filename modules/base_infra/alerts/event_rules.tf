resource "aws_cloudwatch_event_rule" "event_rules" {
  for_each = var.cloudwatch_event_rules_map

  name        = each.key
  description = each.value.description
  is_enabled  = each.value.is_enabled

  event_pattern = templatefile(each.value.event_pattern_file_path, {})

}

#Add event targets
resource "aws_cloudwatch_event_target" "event_targets" {
  for_each = var.cloudwatch_event_rules_map

  rule      = aws_cloudwatch_event_rule.event_rules[each.key].name
  target_id = var.events_target_name
  arn       = var.events_target_arn
}
