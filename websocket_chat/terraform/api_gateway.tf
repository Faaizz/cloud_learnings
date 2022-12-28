# Setup permissions for CW Logs
resource "aws_api_gateway_account" "demo" {
  cloudwatch_role_arn = aws_iam_role.apigw_cw_logs.arn
}

resource "aws_apigatewayv2_api" "main" {
  name                       = local.backend.api.name
  
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_integration" "connect" {
  api_id = aws_apigatewayv2_api.main.id
  integration_type = "HTTP"

  integration_method = "POST"
  integration_uri = "http://${aws_lb.ecs.dns_name}:${local.backend.port}/connect"

  template_selection_expression = "\\$default"

  request_templates = {
    "$default" = <<-EOF
    {
      "connectionId": "$context.connectionId"
    }
    EOF
  }
}

resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "$connect"

  target = "integrations/${aws_apigatewayv2_integration.connect.id}"
}

resource "aws_apigatewayv2_integration_response" "connect" {
  api_id                   = aws_apigatewayv2_api.main.id
  integration_id           = aws_apigatewayv2_integration.connect.id
  integration_response_key = "$default"

  template_selection_expression = "\\$default"
}

resource "aws_apigatewayv2_route_response" "connect" {
  api_id    = aws_apigatewayv2_api.main.id
  route_id = aws_apigatewayv2_route.connect.id
  route_response_key = "$default"
}

# API Stage and Deployment
resource "aws_apigatewayv2_deployment" "main_dev" {
  depends_on = [
    aws_apigatewayv2_integration_response.connect,
    aws_apigatewayv2_route.connect,
    aws_apigatewayv2_route_response.connect
  ]

  lifecycle {
    create_before_destroy = true
  }

  api_id = aws_apigatewayv2_api.main.id
  description = "Initial deployment"
}
resource "aws_apigatewayv2_stage" "dev" {
  api_id = aws_apigatewayv2_api.main.id
  name = "dev"

  stage_variables = {
    "backend_url" = "http://${aws_lb.ecs.dns_name}:${local.backend.port}"
  }

  deployment_id = aws_apigatewayv2_deployment.main_dev.id

  default_route_settings {
    logging_level = "INFO"
    throttling_burst_limit = 5000
    throttling_rate_limit = 10000
  }
}
