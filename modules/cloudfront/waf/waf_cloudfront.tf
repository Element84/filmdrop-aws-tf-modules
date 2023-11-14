resource "aws_waf_geo_match_set" "fd_waf_geo_match_set" {
  name = "FDWAFGeo${local.origin_appendix}"

  dynamic "geo_match_constraint" {
    for_each = var.country_blocklist

    content {
      type  = "Country"
      value = geo_match_constraint.value
    }
  }
}

resource "aws_waf_ipset" "fd_waf_block_ipset" {
  name = "FDWAFCFBlock${local.origin_appendix}"

  dynamic "ip_set_descriptors" {
    for_each = var.ip_blocklist

    content {
      type  = "IPV4"
      value = ip_set_descriptors.value
    }
  }
}

resource "aws_waf_ipset" "fd_waf_allow_ipset" {
  name = "FDWAFCFAllow${local.origin_appendix}"

  dynamic "ip_set_descriptors" {
    for_each = var.whitelist_ips

    content {
      type  = "IPV4"
      value = ip_set_descriptors.value
    }
  }
}

resource "aws_waf_rule" "fd_waf_ip_block_wafrule" {
  name        = "FDWAFIPBlock${local.origin_appendix}"
  metric_name = "FDWAFIPBlock${local.origin_appendix}"

  predicates {
    data_id = aws_waf_ipset.fd_waf_block_ipset.id
    negated = false
    type    = "IPMatch"
  }
}

resource "aws_waf_rule" "fd_waf_ip_accept_wafrule" {
  name        = "FDWAFIPAccept${local.origin_appendix}"
  metric_name = "FDWAFIPAccept${local.origin_appendix}"

  predicates {
    data_id = aws_waf_ipset.fd_waf_allow_ipset.id
    negated = length(var.whitelist_ips) > 0
    type    = "IPMatch"
  }
}

resource "aws_waf_size_constraint_set" "fd_waf_size_constraint_set" {
  name = "FDWAFSize${local.origin_appendix}"

  size_constraints {
    text_transformation = "NONE"
    comparison_operator = "GT"
    size                = var.max_message_body_size

    field_to_match {
      type = "BODY"
    }
  }
}

resource "aws_waf_sql_injection_match_set" "fd_waf_sql_injection_match_set" {
  name = "FDWAFSQLInj${local.origin_appendix}"

  sql_injection_match_tuples {
    text_transformation = "NONE"

    field_to_match {
      type = "ALL_QUERY_ARGS"
    }
  }
}

resource "aws_waf_xss_match_set" "fd_waf_xss_match_set" {
  name = "FDWAFXSS${local.origin_appendix}"

  xss_match_tuples {
    text_transformation = "NONE"

    field_to_match {
      type = "URI"
    }
  }

  xss_match_tuples {
    text_transformation = "NONE"

    field_to_match {
      type = "ALL_QUERY_ARGS"
    }
  }
}

# Create the WAF Rules
resource "aws_waf_rule" "fd_waf_geo_wafrule" {
  name        = "FDWAFGeo${local.origin_appendix}"
  metric_name = "FDWAFGeo${local.origin_appendix}"

  predicates {
    data_id = aws_waf_geo_match_set.fd_waf_geo_match_set.id
    negated = false
    type    = "GeoMatch"
  }
}

resource "aws_waf_rule" "fd_waf_size_wafrule" {
  name        = "FDWAFSize${local.origin_appendix}"
  metric_name = "FDWAFSize${local.origin_appendix}"

  predicates {
    data_id = aws_waf_size_constraint_set.fd_waf_size_constraint_set.id
    negated = false
    type    = "SizeConstraint"
  }
}

resource "aws_waf_rule" "fd_waf_sql_wafrule" {
  name        = "FDWAFSQLInj${local.origin_appendix}"
  metric_name = "FDWAFSQLInj${local.origin_appendix}"

  predicates {
    data_id = aws_waf_sql_injection_match_set.fd_waf_sql_injection_match_set.id
    negated = false
    type    = "SqlInjectionMatch"
  }
}

resource "aws_waf_rule" "fd_waf_xss_wafrule" {
  name        = "FDWAFXSS${local.origin_appendix}"
  metric_name = "FDWAFXSS${local.origin_appendix}"

  predicates {
    data_id = aws_waf_xss_match_set.fd_waf_xss_match_set.id
    negated = false
    type    = "XssMatch"
  }
}

# Create WAF ACL
resource "aws_waf_web_acl" "fd_waf_acl" {
  name        = "FDWAFACL${local.origin_appendix}"
  metric_name = "FDWAFACL${local.origin_appendix}"

  default_action {
    type = "ALLOW"
  }

  logging_configuration {
    log_destination = aws_kinesis_firehose_delivery_stream.fd_waf_cf_logging_firehose_stream.arn
  }

  dynamic "rules" {
    for_each = [aws_waf_rule.fd_waf_xss_wafrule.id, aws_waf_rule.fd_waf_sql_wafrule.id, aws_waf_rule.fd_waf_size_wafrule.id, aws_waf_rule.fd_waf_geo_wafrule.id, aws_waf_rule.fd_waf_ip_block_wafrule.id, aws_waf_rule.fd_waf_ip_accept_wafrule.id]

    content {
      action {
        type = "BLOCK"
      }

      priority = rules.key
      rule_id  = rules.value
      type     = "REGULAR"
    }
  }
}
