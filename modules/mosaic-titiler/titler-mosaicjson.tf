resource "aws_s3_bucket" "lambda-source" {
  bucket = lower("titiler-mosaic-source-${var.project_name}-${var.titiler_stage}")
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "lambda-source-ownership-controls" {
  bucket = aws_s3_bucket.lambda-source.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lambda-source-source-bucket-acl" {
  bucket = aws_s3_bucket.lambda-source.id
  acl    = "private"
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
    version = var.mosaic_titiler_release_tag
    runtime = var.lambda_runtime
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command = <<EOF
wget --quiet \
  https://github.com/Element84/titiler-mosaicjson/releases/download/${var.mosaic_titiler_release_tag}/lambda-${var.lambda_runtime}.zip \
  -O ${path.module}/lambda/${var.mosaic_titiler_release_tag}-lambda-${var.lambda_runtime}.zip
aws s3 cp --quiet \
  ${path.module}/lambda/${var.mosaic_titiler_release_tag}-lambda-${var.lambda_runtime}.zip \
  s3://${aws_s3_bucket.lambda-source.id}/${var.mosaic_titiler_release_tag}-lambda-${var.lambda_runtime}-${self.id}.zip
EOF
  }
}

resource "aws_lambda_function" "titiler-mosaic-lambda" {
  function_name    = "titiler-mosaic-${var.project_name}-${var.titiler_stage}-api"
  description      = "Titiler mosaic API Lambda"
  role             = aws_iam_role.titiler-mosaic-lambda-role.arn
  timeout          = var.titiler_timeout
  memory_size      = var.titiler_memory

  s3_bucket        = aws_s3_bucket.lambda-source.id
  s3_key           = "${var.mosaic_titiler_release_tag}-lambda-${var.lambda_runtime}-${null_resource.download-lambda-source-bundle.id}.zip"
  handler          = "handler.handler"
  runtime          = var.lambda_runtime

  environment {
    variables = {
        CPL_VSIL_CURL_ALLOWED_EXTENSIONS = var.cpl_vsil_curl_allowed_extensions
        CPL_VSIL_CURL_CACHE_SIZE = "200000000"
        GDAL_CACHEMAX = var.gdal_cachemax
        GDAL_DISABLE_READDIR_ON_OPEN = var.gdal_disable_readdir_on_open
        GDAL_HTTP_MERGE_CONSECUTIVE_RANGES = var.gdal_http_merge_consecutive_ranges
        GDAL_HTTP_MULTIPLEX = var.gdal_http_multiplex
        GDAL_HTTP_VERSION = var.gdal_http_version
        GDAL_BAND_BLOCK_CACHE = "HASHSET"
        PYTHONWARNINGS = var.pythonwarnings
        VSI_CACHE = var.vsi_cache
        VSI_CACHE_SIZE = var.vsi_cache_size
        AWS_REQUEST_PAYER = var.aws_request_payer
        GDAL_INGESTED_BYTES_AT_OPEN = var.gdal_ingested_bytes_at_open
        MOSAIC_BACKEND = "dynamodb://"
        MOSAIC_HOST = "${data.aws_region.current.name}/${aws_dynamodb_table.titiler-mosaic-dynamodb-table.name}"
    }
  }

  depends_on = [
    aws_dynamodb_table.titiler-mosaic-dynamodb-table,
  ]
}

resource "aws_apigatewayv2_api" "titiler-mosaic-api-gateway" {
  name          = "${var.project_name}-${var.titiler_stage}-titiler-mosaic"
  protocol_type = "HTTP"
  target        = aws_lambda_function.titiler-mosaic-lambda.arn
}

resource "aws_lambda_permission" "titiler-mosaic-api-gateway_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.titiler-mosaic-lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.titiler-mosaic-api-gateway.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "titiler-mosaic-api-gateway_integration" {
  api_id                 = aws_apigatewayv2_api.titiler-mosaic-api-gateway.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.titiler-mosaic-lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_dynamodb_table" "titiler-mosaic-dynamodb-table" {
  name         = "titiler-mosaic-${var.project_name}-${var.titiler_stage}"
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
