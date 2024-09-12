# This module sets up a CloudFront distribution with a Load Balancer or API Gateway custom origin.
resource "aws_cloudfront_origin_access_identity" "filmdrop_origin_access_identity" {
  comment = "${local.origin_id_prefix} OAI"
}

# Wait for the cert to be ISSUED before setting up endpoint
resource "null_resource" "wait_ssl_issued" {
  triggers = {
    ssl_certificate_arn = var.ssl_certificate_arn
  }

  provisioner "local-exec" {
    # check that the cert is ready
    interpreter = ["bash", "-ec"]
    command     = <<EOF
export AWS_DEFAULT_REGION=${data.aws_region.current.name}
export AWS_REGION=${data.aws_region.current.name}

COUNT=0
STATUS=""
if [[ "${var.ssl_certificate_arn}" == "" ]]; then
  echo "No cert specified."
  exit 0
fi
while [[ "$STATUS" != "ISSUED" ]];
do
  COUNT=$((COUNT + 1))
  if [[ $COUNT -gt 100 ]]; then
    echo "Timed out getting cert status."
    exit 0
  fi
  STATUS=`aws acm describe-certificate --certificate-arn ${var.ssl_certificate_arn} --region us-east-1 | jq -r '.Certificate.Status'`
done
EOF
  }
}

resource "aws_cloudfront_distribution" "filmdrop_managed_cloudfront_distribution" {
  origin {
    domain_name = var.domain_name == "" ? aws_ssm_parameter.cloudfront_custom_origin.value : var.domain_name
    origin_id   = local.origin_id_prefix
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
        name  = var.auth_header_name
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


  enabled             = var.enabled
  is_ipv6_enabled     = var.ipv6_enabled
  default_root_object = var.default_root
  web_acl_id          = var.web_acl_id

  logging_config {
    include_cookies = var.log_cookies
    bucket          = var.create_log_bucket ? aws_s3_bucket.log_bucket[0].bucket_domain_name : var.log_bucket_domain_name
    prefix          = "cloudfront/AWSLogs/${data.aws_caller_identity.current.account_id}/${data.aws_region.current.name}/${var.environment}/${var.project_name}/${var.application_name}"
  }

  aliases = var.domain_aliases

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["HEAD", "GET"]
    compress         = true
    target_origin_id = local.origin_id_prefix

    forwarded_values {
      query_string = true
      headers      = var.custom_http_whitelisted_headers

      cookies {
        forward = "all"
      }
    }

    dynamic "function_association" {
      for_each = var.attach_cf_function == true ? [1] : []
      content {
        event_type   = var.cf_function_event_type
        function_arn = var.create_cf_function == false ? var.cf_function_arn : var.create_cf_basicauth_function ? module.basic_auth_cloudfront_function[0].cf_function_arn : module.cloudfront_function[0].cf_function_arn
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
  }

  price_class = var.price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

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
      response_page_path    = custom_error_response.value["response_page_path"]
    }
  }

  depends_on = [
    null_resource.wait_ssl_issued
  ]
}

resource "aws_ssm_parameter" "cloudfront_custom_origin" {
  name  = "${local.origin_id_prefix}-origin"
  type  = "String"
  value = var.domain_name == "" ? "tmp.filmdrop.io" : var.domain_name

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

module "cloudfront_function" {
  count  = var.create_cf_function == true && var.create_cf_basicauth_function == false ? 1 : 0
  source = "../cf_function"

  name      = var.cf_function_name
  runtime   = var.cf_function_runtime
  code_path = var.cf_function_code_path
}

module "basic_auth_cloudfront_function" {
  count  = var.create_cf_function && var.create_cf_basicauth_function ? 1 : 0
  source = "../basic_auth_function"

  origin_id_prefix = local.origin_id_prefix
}
