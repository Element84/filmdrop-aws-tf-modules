output "titiler_mosaic_api_gateway_id" {
  value = aws_apigatewayv2_api.titiler-mosaic-api-gateway.id
}

output "titiler_mosaic_api_gateway_endpoint" {
  value = "${aws_apigatewayv2_api.titiler-mosaic-api-gateway.id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
}

output "titiler_mosaic_wafv2_web_acl_arn" {
  value = aws_wafv2_web_acl.titiler-mosaic-wafv2-web-acl.arn
}