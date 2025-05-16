moved {
  from = aws_apigatewayv2_api.titiler-mosaic-api-gateway
  to   = aws_apigatewayv2_api.titiler-mosaic-api-gateway[0]
}

moved {
  from = aws_lambda_permission.titiler-mosaic-api-gateway_permission
  to   = aws_lambda_permission.titiler-mosaic-api-gateway_permission[0]
}

moved {
  from = aws_apigatewayv2_integration.titiler-mosaic-api-gateway_integration
  to   = aws_apigatewayv2_integration.titiler-mosaic-api-gateway_integration[0]
}

moved {
  from = aws_wafv2_web_acl.titiler-mosaic-wafv2-web-acl
  to   = aws_wafv2_web_acl.titiler-mosaic-wafv2-web-acl[0]
}
