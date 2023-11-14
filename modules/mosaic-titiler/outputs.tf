output "titiler_mosaic_api_gateway_id" {
  value = aws_apigatewayv2_api.titiler-mosaic-api-gateway.id
}

output "titiler_mosaic_api_gateway_endpoint" {
  value = "${aws_apigatewayv2_api.titiler-mosaic-api-gateway.id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
}
