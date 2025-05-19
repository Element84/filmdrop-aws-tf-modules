resource "aws_s3_bucket" "lambda-source" {
  bucket_prefix = lower("titiler-mosaic-source-${var.project_name}-${var.environment}")
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "lambda-source-ownership-controls" {
  bucket = aws_s3_bucket.lambda-source.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lambda-source-source-bucket-acl" {
  bucket     = aws_s3_bucket.lambda-source.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.lambda-source-ownership-controls]
}

resource "aws_s3_bucket_versioning" "lambda-source-versioning" {
  bucket = aws_s3_bucket.lambda-source.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "null_resource" "download-lambda-source-bundle" {
  triggers = {
    bucket  = aws_s3_bucket.lambda-source.id
    version = var.titiler_mosaicjson_release_tag
    runtime = var.lambda_runtime
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = <<EOF
mkdir -p ${path.module}/lambda
which wget || echo "wget is required, but not found - this is going to fail..."
wget --secure-protocol=TLSv1_2 --quiet \
  https://github.com/Element84/titiler-mosaicjson/releases/download/${var.titiler_mosaicjson_release_tag}/lambda-${var.lambda_runtime}.zip \
  -O ${path.module}/lambda/${var.titiler_mosaicjson_release_tag}-lambda-${var.lambda_runtime}.zip
aws s3 cp --quiet \
  ${path.module}/lambda/${var.titiler_mosaicjson_release_tag}-lambda-${var.lambda_runtime}.zip \
  s3://${aws_s3_bucket.lambda-source.id}/${var.titiler_mosaicjson_release_tag}-lambda-${var.lambda_runtime}-${self.id}.zip
EOF
  }
}

resource "aws_lambda_function" "titiler-mosaic-lambda" {
  function_name = "titiler-mosaic-${var.project_name}-${var.environment}-api"
  description   = "Titiler mosaic API Lambda"
  role          = aws_iam_role.titiler-mosaic-lambda-role.arn
  timeout       = var.titiler_timeout
  memory_size   = var.titiler_memory

  s3_bucket = aws_s3_bucket.lambda-source.id
  s3_key    = "${var.titiler_mosaicjson_release_tag}-lambda-${var.lambda_runtime}-${null_resource.download-lambda-source-bundle.id}.zip"
  handler   = "handler.handler"
  runtime   = var.lambda_runtime

  environment {
    variables = {
      CPL_VSIL_CURL_ALLOWED_EXTENSIONS   = var.cpl_vsil_curl_allowed_extensions
      CPL_VSIL_CURL_CACHE_SIZE           = "200000000"
      GDAL_CACHEMAX                      = var.gdal_cachemax
      GDAL_DISABLE_READDIR_ON_OPEN       = var.gdal_disable_readdir_on_open
      GDAL_HTTP_MERGE_CONSECUTIVE_RANGES = var.gdal_http_merge_consecutive_ranges
      GDAL_HTTP_MULTIPLEX                = var.gdal_http_multiplex
      GDAL_HTTP_VERSION                  = var.gdal_http_version
      GDAL_BAND_BLOCK_CACHE              = "HASHSET"
      PYTHONWARNINGS                     = var.pythonwarnings
      VSI_CACHE                          = var.vsi_cache
      VSI_CACHE_SIZE                     = var.vsi_cache_size
      AWS_REQUEST_PAYER                  = var.aws_request_payer
      GDAL_INGESTED_BYTES_AT_OPEN        = var.gdal_ingested_bytes_at_open
      MOSAIC_BACKEND                     = "dynamodb://"
      MOSAIC_HOST                        = "${data.aws_region.current.name}/${aws_dynamodb_table.titiler-mosaic-dynamodb-table.name}"
      REQUEST_HOST_HEADER_OVERRIDE       = var.request_host_header_override
      MOSAIC_TILE_TIMEOUT                = var.mosaic_tile_timeout
    }
  }

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.vpc_security_group_ids
  }

  depends_on = [
    aws_dynamodb_table.titiler-mosaic-dynamodb-table,
  ]
}

resource "aws_apigatewayv2_api" "titiler-mosaic-api-gateway" {
  count         = var.is_private_endpoint ? 0 : 1
  name          = "${var.project_name}-${var.environment}-titiler-mosaic"
  protocol_type = "HTTP"
  target        = aws_lambda_function.titiler-mosaic-lambda.arn
}

resource "aws_lambda_permission" "titiler-mosaic-api-gateway_permission" {
  count         = var.is_private_endpoint ? 0 : 1
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.titiler-mosaic-lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.titiler-mosaic-api-gateway[0].execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "titiler-mosaic-api-gateway_integration" {
  count                  = var.is_private_endpoint ? 0 : 1
  api_id                 = aws_apigatewayv2_api.titiler-mosaic-api-gateway[0].id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.titiler-mosaic-lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_dynamodb_table" "titiler-mosaic-dynamodb-table" {
  name         = "titiler-mosaic-${var.project_name}-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "mosaicId"
  range_key    = "quadkey"

  attribute {
    name = "mosaicId"
    type = "S"
  }

  attribute {
    name = "quadkey"
    type = "S"
  }

  ttl {
    attribute_name = "timeToLive"
    enabled        = true
  }
}

resource "aws_wafv2_web_acl" "titiler-mosaic-wafv2-web-acl" {
  count       = var.is_private_endpoint ? 0 : 1
  name        = "${var.project_name}-${var.environment}-mosaic"
  description = "WAF rules for ${var.project_name}-${var.environment} mosaic titiler"
  scope       = "CLOUDFRONT"
  provider    = aws.east

  dynamic "default_action" {
    for_each = var.waf_allowed_url == null ? [] : [1]
    content {
      block {}
    }
  }

  dynamic "default_action" {
    for_each = var.waf_allowed_url == null ? [1] : []
    content {
      allow {}
    }
  }

  rule {
    name     = "allow-post-with-correct-stac-api-root"
    priority = 1

    dynamic "action" {
      for_each = var.waf_allowed_url == null ? [] : [1]
      content {
        allow {}
      }
    }

    dynamic "action" {
      for_each = var.waf_allowed_url == null ? [1] : []
      content {
        count {}
      }
    }

    statement {
      and_statement {
        statement {
          # POST /mosaicjson/mosaics
          byte_match_statement {
            positional_constraint = "EXACTLY"
            search_string         = "post"
            field_to_match {
              method {}
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }

        statement {
          # POST /mosaicjson/mosaics
          byte_match_statement {
            positional_constraint = "EXACTLY"
            search_string         = "/mosaicjson/mosaics"
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }

        statement {
          byte_match_statement {
            positional_constraint = "EXACTLY"
            # since any URL will start with "https:", this rule should never match and count
            search_string = var.waf_allowed_url == null ? "X" : var.waf_allowed_url
            field_to_match {
              json_body {
                match_pattern {
                  included_paths = ["/stac_api_root"]
                }
                match_scope               = "VALUE"
                invalid_fallback_behavior = "NO_MATCH"
                oversize_handling         = "NO_MATCH"
              }
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.project_name}-${var.environment}-mosaic-allow-post"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "allow-mosaic-options-for-cors"
    priority = 2

    dynamic "action" {
      for_each = var.waf_allowed_url == null ? [] : [1]
      content {
        allow {}
      }
    }

    dynamic "action" {
      for_each = var.waf_allowed_url == null ? [1] : []
      content {
        count {}
      }
    }

    statement {
      and_statement {
        statement {
          # OPTIONS /mosaicjson/mosaics
          byte_match_statement {
            positional_constraint = "EXACTLY"
            search_string         = "options"
            field_to_match {
              method {}
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }

        statement {
          # OPTIONS /mosaicjson/mosaics
          byte_match_statement {
            positional_constraint = "EXACTLY"
            search_string         = "/mosaicjson/mosaics"
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.project_name}-${var.environment}-mosaic-allow-options"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "allow-get-stac-tiles-with-url-query-param"
    priority = 3

    dynamic "action" {
      for_each = var.waf_allowed_url == null ? [] : [1]
      content {
        allow {}
      }
    }

    dynamic "action" {
      for_each = var.waf_allowed_url == null ? [1] : []
      content {
        count {}
      }
    }

    statement {
      and_statement {
        statement {
          # GET /stac/tiles/*
          byte_match_statement {
            positional_constraint = "EXACTLY"
            search_string         = "get"
            field_to_match {
              method {}
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }

        statement {
          # GET /stac/tiles/*
          byte_match_statement {
            positional_constraint = "STARTS_WITH"
            search_string         = "/stac/tiles/"
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }

        statement {
          byte_match_statement {
            positional_constraint = "STARTS_WITH"
            # since any URL will start with "https:", this rule should never match and count
            search_string = var.waf_allowed_url == null ? "X" : var.waf_allowed_url

            field_to_match {
              single_query_argument {
                name = "url"
              }
            }

            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }

      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.project_name}-${var.environment}-mosaic-allow-get"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${var.project_name}-${var.environment}-mosaic-waf-rules"
    sampled_requests_enabled   = false
  }
}

resource "null_resource" "cleanup_bucket" {
  triggers = {
    bucket_name = aws_s3_bucket.lambda-source.id
    region      = data.aws_region.current.name
    account     = data.aws_caller_identity.current.account_id
  }

  provisioner "local-exec" {
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}

echo "FilmDrop CloudFront bucket has been created."

aws s3 ls s3://${self.triggers.bucket_name}
EOF

  }


  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
export AWS_DEFAULT_REGION=${self.triggers.account}
export AWS_REGION=${self.triggers.region}

echo "Cleaning FilmDrop bucket."

aws s3 rm s3://${self.triggers.bucket_name}/ --recursive
EOF
  }


  depends_on = [
    aws_s3_bucket.lambda-source
  ]
}
