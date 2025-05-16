output "titiler_mosaic_api_gateway_id" {
  value = var.is_private_endpoint ? aws_api_gateway_rest_api.titiler_api_gateway[0].id : aws_apigatewayv2_api.titiler-mosaic-api-gateway[0].id
}

output "titiler_mosaic_api_gateway_endpoint" {
  value = var.is_private_endpoint ? "${aws_api_gateway_rest_api.titiler_api_gateway[0].id}.execute-api.${data.aws_region.current.name}.amazonaws.com" : "${aws_apigatewayv2_api.titiler-mosaic-api-gateway[0].id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
}

output "titiler_mosaic_wafv2_web_acl_arn" {
  value = var.is_private_endpoint ? "" : aws_wafv2_web_acl.titiler-mosaic-wafv2-web-acl[0].arn
}
