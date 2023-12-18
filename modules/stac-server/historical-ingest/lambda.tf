resource "aws_lambda_function" "historical_ingest" {
  filename      = "${path.module}/lambda.zip"
  function_name = "${var.stac_server_name_prefix}-historical-ingest"
  description   = "Historical Ingest Lambda"
  role          = var.stac_server_lambda_iam_role_arn
  handler       = "main.lambda_handler"
  runtime       = "python3.9"
  timeout       = 900
  memory_size   = 1536

  environment {
    variables = {
      MIN_LAT           = var.destination_collections_min_lat
      MIN_LONG          = var.destination_collections_min_long
      MAX_LAT           = var.destination_collections_max_lat
      MAX_LONG          = var.destination_collections_max_long
      COLLECTIONS       = var.destination_collections_list
      DATE_START        = var.date_start
      DATE_END          = var.date_end
      STAC_SOURCE_URL   = var.source_catalog_url
      STAC_DEST_URL     = var.destination_catalog_url
      INGEST_SQS_URL    = var.ingest_sqs_url
      HISTORICAL_INGEST = var.include_historical_ingest
    }
  }
}

resource "aws_lambda_invocation" "run_historical_ingest" {
  function_name = aws_lambda_function.historical_ingest.function_name

  input = "{}"
}
