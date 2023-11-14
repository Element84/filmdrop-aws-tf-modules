resource "aws_wafv2_web_acl" "cf_web_acl" {
  provider    = aws.east
  name        = var.web_acl_name
  description = var.web_acl_desc
  scope       = "CLOUDFRONT"

  dynamic "default_action" {
    for_each = var.wacl_default_action == "block" ? [1] : []
    content {
      block {}
    }
  }

  dynamic "default_action" {
    for_each = var.wacl_default_action == "allow" ? [1] : []
    content {
      allow {}
    }
  }

  dynamic "rule" {
    for_each = var.waf_rules_map
    content {
      name     = rule.key
      priority = rule.value.priority

      dynamic "action" {
        for_each = rule.value.rule_action == "allow" ? [1] : []
        content {
          allow {}
        }
      }

      dynamic "action" {
        for_each = rule.value.rule_action == "block" ? [1] : []
        content {
          block {}
        }
      }

      statement {
        byte_match_statement {
          field_to_match {
            single_query_argument {
              name = rule.value.match_param_name
            }
          }
          positional_constraint = rule.value.positional_constraint
          search_string         = rule.value.search_string
          text_transformation {
            priority = rule.value.text_transformation_priority
            type     = rule.value.text_transformation_type
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = false
        metric_name                = rule.key
        sampled_requests_enabled   = false
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.wacl_cloudwatch_metrics_enabled
    metric_name                = local.valid_web_acl_name
    sampled_requests_enabled   = var.wacl_sampled_requests_enabled
  }
}

