output "api_endpoint" {
  description = "Invoke URL for API Gateway"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

