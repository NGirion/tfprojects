output "lambda_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
  description = "Public URL of the Lambda-powered API"
}

