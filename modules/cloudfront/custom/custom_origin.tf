# This module sets up a CloudFront distribution with a Load Balancer or API Gateway custom origin.
resource "aws_cloudfront_origin_access_identity" "filmdrop_origin_access_identity" {
  comment = "${var.logging_origin_id} OAI"
}

# Check to see that the cert is ISSUED before setting up endpoint
resource "null_resource" "check_ssl" {
  triggers = {
    ssl_change = var.ssl_certificate_arn
  }

  provisioner "local-exec" {
    # check that the cert is ready
    interpreter = ["bash", "-ec"]
    command = <<EOF
export AWS_DEFAULT_REGION=${data.aws_region.current.name}
export AWS_REGION=${data.aws_region.current.name}

COUNT=0
STATUS=""
if [[ "${var.ssl_certificate_arn}" == "" ]]; then
  echo "No cert specified.  No issue check needed."
  exit 0
fi
while [[ "$STATUS" != "ISSUED" ]];
do
  COUNT=$((COUNT + 1))
  if [[ $COUNT -gt 150 ]]; then  # bail out after 150 tries
    echo "Timeout getting cert status."
    exit 0
  fi
  STATUS=`aws acm describe-certificate --certificate-arn ${var.ssl_certificate_arn} --region us-east-1 | jq -r '.Certificate.Status'`
done
EOF
  }
}

resource "aws_cloudfront_distribution" "filmdrop_managed_cloudfront_distribution" {
  origin {
    domain_name = var.domain_name
    origin_id   = var.logging_origin_id
    origin_path = var.origin_path

    custom_header {
      name  = "X-Forwarded-Host"
      value = length(var.domain_aliases) > 0 ? element(concat(var.domain_aliases, [""]), 0) : aws_ssm_parameter.cloudfront_x_forwarded_host.value
    }

    custom_header {
      name  = "X-Forwarded-Proto"
      value = "https"
    }

    dynamic "custom_header" {
      for_each = { for i, j in [var.auth_header_name] : i => j if var.auth_header_name != "" }

      content {
        name = var.auth_header_name
        value = var.auth_header_value
      }
    }

    custom_origin_config {
      http_port                = var.origin_http_port
      https_port               = var.origin_https_port
      origin_protocol_policy   = var.origin_protocol_policy
      origin_ssl_protocols     = var.origin_ssl_protocols
      origin_keepalive_timeout = var.origin_keepalive_timeout
      origin_read_timeout      = var.origin_read_timeout
    }
  }

  origin {
    domain_name = var.error_pages_domain_name
    origin_id   = var.error_pages_id

    s3_origin_config {
      origin_access_identity = var.cloudfront_access_identity_path == "" ? aws_cloudfront_origin_access_identity.filmdrop_origin_access_identity.cloudfront_access_identity_path : var.cloudfront_access_identity_path
    }
  }

  # Allows for a MAP of custom origins, this is for cases were extra configuration is needed at the CloudFront level
  # in order to support features like path-based routing for multiple origins
  dynamic "origin" {
    for_each = { for k, v in var.additional_cloudfront_origins : k => v if contains(keys(v), "origin_id") }

    content {
      domain_name = origin.value["domain_name"]
      origin_id   = origin.value["origin_id"]
      origin_path = origin.value["origin_path"]

      dynamic "s3_origin_config" {
        for_each = { for i, j in origin.value["s3_origin_config"] : i => j if contains(keys(j), "origin_access_identity") }

        content {
          origin_access_identity = s3_origin_config.value["origin_access_identity"]
        }
      }

      dynamic "custom_header" {
        for_each = { for i, j in origin.value["custom_header"] : i => j if contains(keys(j), "name") }

        content {
          name = custom_header.value["name"]
          value = custom_header.value["value"]
        }
      }

      dynamic "custom_origin_config" {
        for_each = { for i, j in origin.value["custom_origin_config"] : i => j if contains(keys(j), "origin_protocol_policy") }

        content {
          http_port                 = custom_origin_config.value["http_port"]
          https_port                = custom_origin_config.value["https_port"]
          origin_protocol_policy    = custom_origin_config.value["origin_protocol_policy"]
          origin_ssl_protocols      = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
          origin_keepalive_timeout  = custom_origin_config.value["origin_keepalive_timeout"]
          origin_read_timeout       = custom_origin_config.value["origin_read_timeout"]
        }
      }
    }
  }

  enabled             = var.enabled
  is_ipv6_enabled     = var.ipv6_enabled
  default_root_object = var.default_root
  web_acl_id          = var.create_waf_rule == false ? var.web_acl_id : module.cloudfront_waf[0].web_acl_id

  logging_config {
    include_cookies = var.log_cookies
    bucket          = var.logging_domain_name
    prefix          = "cloudfront/AWSLogs/${data.aws_caller_identity.current.account_id}/${data.aws_region.current.name}/${var.log_prefix}"
  }

  aliases = var.domain_aliases

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["HEAD", "GET"]
    compress         = true
    target_origin_id = var.logging_origin_id

    forwarded_values {
      query_string = true
      headers      = var.custom_http_whitelisted_headers

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
  }

  ordered_cache_behavior {
    path_pattern     = "/${var.error_pages_id}*"
    allowed_methods  = ["HEAD", "GET", "OPTIONS"]
    cached_methods   = ["HEAD", "GET"]
    compress         = true
    target_origin_id = var.error_pages_id

    forwarded_values {
      query_string = true
      headers      = var.custom_s3_whitelisted_headers

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
  }

  dynamic "ordered_cache_behavior" {
    for_each = { for k, v in var.additional_cloudfront_origins : k => v if contains(keys(v), "origin_id") }
    
    content {
      path_pattern     = "${ordered_cache_behavior.value["routing_path"]}*"
      allowed_methods  = ["HEAD", "GET", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods   = ["HEAD", "GET"]
      compress         = true
      target_origin_id = ordered_cache_behavior.value["origin_id"]

      # Checking for ALB backends
      dynamic "forwarded_values" {
        for_each = contains(split(".", ordered_cache_behavior.value["domain_name"]), "elb") ? [""] : []
        content {
          query_string = true
          headers      = ["*"]

          cookies {
            forward = "all"
          }
        }
      }

      # Checking for API Gateway backends
      dynamic "forwarded_values" {
        for_each = contains(split(".", ordered_cache_behavior.value["domain_name"]), "execute-api") ? [""] : []
        content {
          query_string = true
          headers      = ["Authorization", "Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method", "User-Agent", "Accept"]

          cookies {
            forward = "all"
          }
        }
      }

      # Checking for other backends
      dynamic "forwarded_values" {
        for_each = contains(split(".", ordered_cache_behavior.value["domain_name"]), "elb") || contains(split(".", ordered_cache_behavior.value["domain_name"]), "execute-api") ?  [] : [""]
        content {
          query_string = true
          headers      = ["User-Agent"]

          cookies {
            forward = "all"
          }
        }
      }

      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = var.min_ttl
      default_ttl            = var.default_ttl
      max_ttl                = var.max_ttl

      # If caching is disabled, use the AWS provided "Managed-CachingDisabled" cache policy and "Managed-AllViewer" origin request policy
      origin_request_policy_id = var.caching_disabled ? "216adef6-5c7f-47e4-b989-5492eafa07d3" : null
      cache_policy_id          = var.caching_disabled ? "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" : null
    }
  }

  price_class = var.price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Use different viewer_certificate parameter for CloudFront endpoints with and without
  # Custom DNS, this avoids updating CloudFront on every Apply
  dynamic "viewer_certificate" {
    for_each = { for k, v in [var.ssl_certificate_arn] : k =>
    v if var.ssl_certificate_arn != "" }
    content {
      acm_certificate_arn            = var.ssl_certificate_arn
      ssl_support_method             = "sni-only"
      cloudfront_default_certificate = false
      minimum_protocol_version       = var.minimum_protocol_version
    }
  }

  dynamic "viewer_certificate" {
    for_each = { for k, v in [var.minimum_protocol_version] : k =>
    v if var.ssl_certificate_arn == "" }
    content {
      cloudfront_default_certificate = true
    }
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_response

    content {
      error_caching_min_ttl = custom_error_response.value["error_caching_min_ttl"]
      error_code            = custom_error_response.value["error_code"]
      response_code         = custom_error_response.value["response_code"]
      response_page_path    = "/${var.error_pages_id}${custom_error_response.value["response_page_path"]}"
    }
  }

  depends_on = [
    null_resource.check_ssl
  ]
}

module "cloudfront_waf" {
  count = var.create_waf_rule == false ? 0 : 1
  source = "../waf"

  logging_bucket_name = var.logging_bucket_name
  whitelist_ips       = var.whitelist_ips
  ip_blocklist        = var.ip_blocklist
  waf_appendix        = replace(replace(var.log_prefix, "_", ""), "-", "")
}
