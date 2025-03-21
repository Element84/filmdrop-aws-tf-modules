resource "aws_wafv2_ip_set" "fd_waf_block_ipset" {
  name               = "FDWAFCFBlock${local.origin_appendix}"
  description        = "Blocked IPs on ${local.origin_appendix}"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.ip_blocklist
}

resource "aws_wafv2_ip_set" "fd_waf_allow_ipset" {
  name               = "FDWAFCFAllow${local.origin_appendix}"
  description        = "Allowed IPs on ${local.origin_appendix}"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.whitelist_ips
}

resource "aws_wafv2_web_acl" "fd_waf_acl" {
  name        = "FDWAFACL${local.origin_appendix}"
  description = "WAF rules for CloudFront ${local.origin_appendix}"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }
  rule {
    name     = "${local.origin_appendix}-allow-whitelisted-ips-only"
    priority = 1

    dynamic "action" {
      for_each = length(var.whitelist_ips) > 0 ? [1] : []
      content {
        block {}
      }
    }

    dynamic "action" {
      for_each = length(var.whitelist_ips) == 0 ? [1] : []
      content {
        count {}
      }
    }

    statement {
      not_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.fd_waf_allow_ipset.arn
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${local.origin_appendix}-allow-whitelisted-ips-only"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "${local.origin_appendix}-block-blacklisted-ips"
    priority = 2

    dynamic "action" {
      for_each = length(var.ip_blocklist) > 0 ? [1] : []
      content {
        block {}
      }
    }

    dynamic "action" {
      for_each = length(var.ip_blocklist) == 0 ? [1] : []
      content {
        count {}
      }
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.fd_waf_block_ipset.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${local.origin_appendix}-block-blacklisted-ips"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "${local.origin_appendix}-http-body-max-length"
    priority = 3

    action {
      block {}
    }

    statement {
      size_constraint_statement {
        comparison_operator = "GT"
        size                = var.max_message_body_size
        field_to_match {
          body {}
        }
        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${local.origin_appendix}-http-body-max-length"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "${local.origin_appendix}-sql-injection"
    priority = 4

    action {
      block {}
    }

    statement {

      sqli_match_statement {
        text_transformation {
          priority = 0
          type     = "NONE"
        }

        field_to_match {
          all_query_arguments {}
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${local.origin_appendix}-sql-injection"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "${local.origin_appendix}-xss"
    priority = 5

    action {
      block {}
    }

    statement {
      or_statement {
        statement {
          xss_match_statement {
            text_transformation {
              priority = 0
              type     = "NONE"
            }

            field_to_match {
              uri_path {}
            }
          }
        }
        statement {
          xss_match_statement {
            text_transformation {
              priority = 0
              type     = "NONE"
            }

            field_to_match {
              all_query_arguments {}
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${local.origin_appendix}-xss"
      sampled_requests_enabled   = false
    }
  }

  dynamic "rule" {
    for_each = length(var.country_blocklist) > 0 ? [1] : []

    content {
      name     = "${local.origin_appendix}-geo-country-blocklist"
      priority = 6

      action {
        block {}
      }
      statement {
        geo_match_statement {
          country_codes = var.country_blocklist
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = false
        metric_name                = "${local.origin_appendix}-geo-country-blocklist"
        sampled_requests_enabled   = false
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${local.origin_appendix}-cloudfront-waf-rules"
    sampled_requests_enabled   = false
  }
}
