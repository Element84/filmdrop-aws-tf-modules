output "titiler_api_gateway_id" {
  value = var.is_private_endpoint ? aws_api_gateway_rest_api.titiler_api_gateway[0].id : aws_apigatewayv2_api.titiler-api-gateway[0].id
}

output "titiler_api_gateway_endpoint" {
  value = var.is_private_endpoint ? "${aws_api_gateway_rest_api.titiler_api_gateway[0].id}.execute-api.${data.aws_region.current.region}.amazonaws.com" : "${aws_apigatewayv2_api.titiler-api-gateway[0].id}.execute-api.${data.aws_region.current.region}.amazonaws.com"
}

output "titiler_wafv2_web_acl_arn" {
  value = var.is_private_endpoint ? "" : aws_wafv2_web_acl.titiler-wafv2-web-acl[0].arn
}

output "titiler_vpce_dns_regional" {
  value = local.create_vpce ? {
    dns_name       = aws_vpc_endpoint.titiler_api_gateway_private[0].dns_entry[0].dns_name
    hosted_zone_id = aws_vpc_endpoint.titiler_api_gateway_private[0].dns_entry[0].hosted_zone_id
  } : null
  description = <<-DESCRIPTION
    When titiler is deployed with is_private_endpoint = true, and the user has *not* indicated they are using a custom
    vpce endpoint (local.custom_vpce_id is null),this output provides the VPC Endpoint DNS information.
    In particular, this points to the regional DNS (rather than any of the subnet-specific DNS entries).
    This can be used to create internal DNS records that point to the titiler private API Gateway endpoint.
  DESCRIPTION
}
