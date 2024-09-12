# This module sets up a CloudFront distribution with an S3 origin.
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
  echo "No cert specified.  No issue check needed."
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
    domain_name = var.create_content_website == false ? var.domain_name : module.content_website[0].content_bucket_regional_domain_name
    origin_id   = local.origin_id_prefix

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.filmdrop_origin_access_identity.cloudfront_access_identity_path
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
    allowed_methods  = ["HEAD", "GET", "OPTIONS"]
    cached_methods   = ["HEAD", "GET"]
    compress         = true
    target_origin_id = local.origin_id_prefix

    # If caching is disabled, this configuration is contained in the s3_origin_request_policy resource
    dynamic "forwarded_values" {
      for_each = var.caching_disabled ? [] : [""]
      content {
        query_string = true
        headers      = var.custom_s3_whitelisted_headers

        cookies {
          forward = "all"
        }
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

    # If caching is disabled, use the AWS provided "Managed-CachingDisabled" cache policy and "Managed-AllViewer" origin request policy
    origin_request_policy_id = var.caching_disabled ? "216adef6-5c7f-47e4-b989-5492eafa07d3" : null
    cache_policy_id          = var.caching_disabled ? "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" : null
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

module "content_website" {
  providers = {
    aws = aws.main
  }
  count  = var.create_content_website == false ? 0 : 1
  source = "../content"

  origin_id = local.origin_id_prefix
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
