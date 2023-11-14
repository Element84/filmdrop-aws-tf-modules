# setup geo blocks
resource "aws_waf_geo_match_set" "geo_match_set" {
  name = "FilmDropWAFGeo${var.waf_appendix}"

  dynamic "geo_match_constraint" {
    for_each = var.country_blocklist

    content {
      type  = "Country"
      value = geo_match_constraint.value
    }
  }
}

resource "aws_waf_ipset" "block_ipset" {
  name = "FilmDropWAFCFStackBlockIpset${var.waf_appendix}"

  dynamic "ip_set_descriptors" {
    for_each = var.ip_blocklist

    content {
      type  = "IPV4"
      value = ip_set_descriptors.value
    }
  }
}

resource "aws_waf_ipset" "allow_ipset" {
  name = "FilmDropWAFCFStackAllowIpset${var.waf_appendix}"

  dynamic "ip_set_descriptors" {
    for_each = var.whitelist_ips

    content {
      type  = "IPV4"
      value = ip_set_descriptors.value
    }
  }
}

# setup ip blocks
resource "aws_waf_rule" "ip_block_wafrule" {
  name        = "FilmDropWAFIPBlockRule${var.waf_appendix}"
  metric_name = "FilmDropWAFIPBlockRule${var.waf_appendix}"

  predicates {
    data_id = aws_waf_ipset.block_ipset.id
    negated = false
    type    = "IPMatch"
  }
}

# setup ip whitelist
resource "aws_waf_rule" "ip_accept_wafrule" {
  name        = "FilmDropWAFIPAcceptRule${var.waf_appendix}"
  metric_name = "FilmDropWAFIPAcceptRule${var.waf_appendix}"

  predicates {
    data_id = aws_waf_ipset.allow_ipset.id
    negated = length(var.whitelist_ips) > 0
    type    = "IPMatch"
  }
}

# size constraints
resource "aws_waf_size_constraint_set" "size_constraint_set" {
  name = "FilmDropWAFSize${var.waf_appendix}"

  size_constraints {
    text_transformation = "NONE"
    comparison_operator = "GT"
    size                = var.max_message_body_size

    field_to_match {
      type = "BODY"
    }
  }
}

# SQL Injection filter
resource "aws_waf_sql_injection_match_set" "sql_injection_match_set" {
  name = "FilmDropWAFSQLInj${var.waf_appendix}"

  sql_injection_match_tuples {
    text_transformation = "NONE"

    field_to_match {
      type = "ALL_QUERY_ARGS"
    }
  }
}

# Cross site scripting check
resource "aws_waf_xss_match_set" "xss_match_set" {
  name = "FilmDropWAFXSS${var.waf_appendix}"

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
resource "aws_waf_rule" "geo_wafrule" {
  name        = "FilmDropWAFGeoRule${var.waf_appendix}"
  metric_name = "FilmDropWAFGeoRule${var.waf_appendix}"

  predicates {
    data_id = aws_waf_geo_match_set.geo_match_set.id
    negated = false
    type    = "GeoMatch"
  }
}

resource "aws_waf_rule" "size_wafrule" {
  name        = "FilmDropWAFSizeRule${var.waf_appendix}"
  metric_name = "FilmDropWAFSizeRule${var.waf_appendix}"

  predicates {
    data_id = aws_waf_size_constraint_set.size_constraint_set.id
    negated = false
    type    = "SizeConstraint"
  }
}

resource "aws_waf_rule" "sql_wafrule" {
  name        = "FilmDropWAFSQLInjRule${var.waf_appendix}"
  metric_name = "FilmDropWAFSQLInjRule${var.waf_appendix}"

  predicates {
    data_id = aws_waf_sql_injection_match_set.sql_injection_match_set.id
    negated = false
    type    = "SqlInjectionMatch"
  }
}

resource "aws_waf_rule" "xss_wafrule" {
  name        = "FilmDropWAFXSSRule${var.waf_appendix}"
  metric_name = "FilmDropWAFXSSRule${var.waf_appendix}"

  predicates {
    data_id = aws_waf_xss_match_set.xss_match_set.id
    negated = false
    type    = "XssMatch"
  }
}

# Create WAF ACL
resource "aws_waf_web_acl" "waf_acl" {
  name        = "FilmDropWAFACL${var.waf_appendix}"
  metric_name = "FilmDropWAFACL${var.waf_appendix}"

  default_action {
    type = "ALLOW"
  }

  logging_configuration {
    log_destination = aws_kinesis_firehose_delivery_stream.waf_cf_logging_firehose_stream.arn
  }

  dynamic "rules" {
    for_each = [aws_waf_rule.xss_wafrule.id, aws_waf_rule.sql_wafrule.id, aws_waf_rule.size_wafrule.id, aws_waf_rule.geo_wafrule.id, aws_waf_rule.ip_block_wafrule.id, aws_waf_rule.ip_accept_wafrule.id]

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
