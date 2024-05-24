module "titiler_docker_ecr" {
  source = "./docker-images"

  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  security_group_ids = var.security_group_ids
  prefix             = var.prefix
  environment        = var.environment
}

resource "aws_lambda_function" "titiler_lambda" {
  function_name = "titiler-${var.project_name}-${var.environment}-api"
  description   = "Titiler API Lambda"
  role          = aws_iam_role.titiler_lambda_role.arn
  package_type  = "Image"
  image_uri     = "${module.titiler_docker_ecr.titiler_repo}:latest"
  timeout       = var.titiler_timeout
  memory_size   = var.titiler_memory

  environment {
    variables = {
      CPL_VSIL_CURL_ALLOWED_EXTENSIONS   = var.cpl_vsil_curl_allowed_extensions
      GDAL_CACHEMAX                      = var.gdal_cachemax
      GDAL_DISABLE_READDIR_ON_OPEN       = var.gdal_disable_readdir_on_open
      GDAL_HTTP_MERGE_CONSECUTIVE_RANGES = var.gdal_http_merge_consecutive_ranges
      GDAL_HTTP_MULTIPLEX                = var.gdal_http_multiplex
      GDAL_HTTP_VERSION                  = var.gdal_http_version
      GDAL_INGESTED_BYTES_AT_OPEN        = var.gdal_ingested_bytes_at_open
      PYTHONWARNINGS                     = var.pythonwarnings
      VSI_CACHE                          = var.vsi_cache
      VSI_CACHE_SIZE                     = var.vsi_cache_size
      AWS_REQUEST_PAYER                  = var.aws_request_payer
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = var.security_group_ids
  }

  depends_on = [
    module.titiler_docker_ecr
  ]
}


resource "aws_apigatewayv2_api" "titiler_api_gateway" {
  name          = "${var.environment}-titiler"
  protocol_type = "HTTP"
  target        = aws_lambda_function.titiler_lambda.arn
}

# Permission
resource "aws_lambda_permission" "titiler_api_gateway_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.titiler_lambda.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.titiler_api_gateway.execution_arn}/*/*"
}
