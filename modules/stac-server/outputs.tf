output "stac_server_opensearch_domain" {
  value = local.opensearch_domain
}

output "stac_server_opensearch_endpoint" {
  value = local.opensearch_endpoint
}

output "stac_server_api_domain_name" {
  # Given:
  #  - https://abcd1234.execute-api.us-west-2.amazonaws.com/prod
  # The following is returned for a PRIVATE API Gateway (VPCe must be included):
  #  - abcd1234-vpce-123456789.execute-api.us-west-2.amazonaws.com
  # Or for an EDGE API Gateway:
  #  - abcd1234.execute-api.us-west-2.amazonaws.com
  value = (
    local.is_private_endpoint
    ? replace(
      element(split("/", aws_api_gateway_deployment.stac_server_api_gateway.invoke_url), 2),
      aws_api_gateway_rest_api.stac_server_api_gateway.id,
      "${aws_api_gateway_rest_api.stac_server_api_gateway.id}-${aws_vpc_endpoint.stac_server_api_gateway_private[0].id}"
    )
    : element(split("/", aws_api_gateway_deployment.stac_server_api_gateway.invoke_url), 2)
  )
}

output "stac_server_api_path" {
  value = "/${element(
    split(
      "/",
      aws_api_gateway_deployment.stac_server_api_gateway.invoke_url,
    ),
    3,
  )}"
}

output "stac_server_opensearch_name" {
  value = lower(var.opensearch_stac_server_domain_name_override == null ? "${local.name_prefix}-stac-server" : var.opensearch_stac_server_domain_name_override)
}

output "stac_server_ingest_queue_arn" {
  value = aws_sqs_queue.stac_server_ingest_sqs_queue.arn
}

output "stac_server_ingest_queue_url" {
  value = aws_sqs_queue.stac_server_ingest_sqs_queue.url
}

output "stac_server_name_prefix" {
  value = "${local.name_prefix}-stac-server"
}

output "stac_server_lambda_iam_role_arn" {
  value = aws_iam_role.stac_api_lambda_role.arn
}

output "stac_server_ingest_sns_topic_arn" {
  value = aws_sns_topic.stac_server_ingest_sns_topic.arn
}

output "stac_server_post_ingest_sns_topic_arn" {
  value = aws_sns_topic.stac_server_post_ingest_sns_topic.arn
}

output "stac_server_api_gateway_id" {
  value = aws_api_gateway_rest_api.stac_server_api_gateway.id
}

output "stac_server_ingest_lambda_name" {
  value = aws_lambda_function.stac_server_ingest.function_name
}

output "stac_server_ingest_lambda_arn" {
  value = aws_lambda_function.stac_server_ingest.arn
}

output "stac_server_api_lambda_name" {
  value = aws_lambda_function.stac_server_api.function_name
}

output "stac_server_api_lambda_arn" {
  value = aws_lambda_function.stac_server_api.arn
}