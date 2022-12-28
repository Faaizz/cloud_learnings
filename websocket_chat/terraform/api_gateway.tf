# Setup permissions for CW Logs
resource "aws_api_gateway_account" "demo" {
  cloudwatch_role_arn = aws_iam_role.apigw_cw_logs.arn
}

resource "aws_apigatewayv2_api" "main" {
  name                       = local.backend.api.name
  
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

# API Stage and Deployment
resource "aws_apigatewayv2_stage" "dev" {
  api_id = aws_apigatewayv2_api.main.id
  name = "dev"

  # enable auto-deploy such that a new deployment is made after adding the 'message' route
  auto_deploy = true

  stage_variables = {
    "backend_url" = "http://${aws_lb.ecs.dns_name}:${local.backend.port}"
  }

  default_route_settings {
    data_trace_enabled = true
    logging_level = "INFO"
    throttling_burst_limit = 5000
    throttling_rate_limit = 10000
  }
}

# Generalized integration request
resource "aws_apigatewayv2_integration" "general" {
  for_each = local.backend.api.routes

  api_id = aws_apigatewayv2_api.main.id
  integration_type = "HTTP"

  integration_method = "POST"
  integration_uri = "http://${aws_lb.ecs.dns_name}:${local.backend.port}/${each.value.path}"

  template_selection_expression = "\\$default"

  request_templates = each.value.request_templates
}

# Generalized route
resource "aws_apigatewayv2_route" "general" {
  for_each = local.backend.api.routes

  api_id    = aws_apigatewayv2_api.main.id
  route_key = each.value.route_key

  target = "integrations/${aws_apigatewayv2_integration.general[each.key].id}"
}

# Generalized integration response
resource "aws_apigatewayv2_integration_response" "general" {
  for_each = local.backend.api.routes

  api_id                   = aws_apigatewayv2_api.main.id
  integration_id           = aws_apigatewayv2_integration.general[each.key].id
  integration_response_key = "$default"

  template_selection_expression = "\\$default"
}

# Generalized route response
resource "aws_apigatewayv2_route_response" "general" {
  for_each = local.backend.api.routes

  api_id    = aws_apigatewayv2_api.main.id
  route_id = aws_apigatewayv2_route.general[each.key].id
  route_response_key = "$default"
}


# Message route and integrations
resource "aws_apigatewayv2_integration" "message" {
  depends_on = [
    aws_apigatewayv2_stage.dev,
  ]

  api_id = aws_apigatewayv2_api.main.id
  integration_type = "HTTP"

  integration_method = "POST"
  integration_uri = "http://${aws_lb.ecs.dns_name}:${local.backend.port}/message"

  template_selection_expression = "\\$default"

  request_templates = {
    "$default" = <<-EOF
      {
        "connectionId": "$context.connectionId",
        "username": $input.json('$.username'),
        "message": $input.json('$.message'),
        "url": "${join("", ["https://", split("wss://", aws_apigatewayv2_stage.dev.invoke_url)[1]])}"
      }
      EOF
  }
}

resource "aws_apigatewayv2_route" "message" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "message"

  target = "integrations/${aws_apigatewayv2_integration.message.id}"
}

resource "aws_apigatewayv2_integration_response" "message" {
  api_id                   = aws_apigatewayv2_api.main.id
  integration_id           = aws_apigatewayv2_integration.message.id
  integration_response_key = "$default"

  template_selection_expression = "\\$default"
}

resource "aws_apigatewayv2_route_response" "message" {
  api_id    = aws_apigatewayv2_api.main.id
  route_id = aws_apigatewayv2_route.message.id
  route_response_key = "$default"
}


# Online route and integrations
resource "aws_apigatewayv2_integration" "online" {
  depends_on = [
    aws_apigatewayv2_stage.dev,
  ]

  api_id = aws_apigatewayv2_api.main.id
  integration_type = "HTTP"

  integration_method = "POST"
  integration_uri = "http://${aws_lb.ecs.dns_name}:${local.backend.port}/online"

  template_selection_expression = "\\$default"

  request_templates = {
    "$default" = <<-EOF
      {
        "connectionId": "$context.connectionId",
        "url": "${join("", ["https://", split("wss://", aws_apigatewayv2_stage.dev.invoke_url)[1]])}"
      }
      EOF
  }
}

resource "aws_apigatewayv2_route" "online" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "online"

  target = "integrations/${aws_apigatewayv2_integration.online.id}"
}

resource "aws_apigatewayv2_integration_response" "online" {
  api_id                   = aws_apigatewayv2_api.main.id
  integration_id           = aws_apigatewayv2_integration.online.id
  integration_response_key = "$default"

  template_selection_expression = "\\$default"

  response_templates = {
    "$default" = "{}"
  }
}

resource "aws_apigatewayv2_route_response" "online" {
  api_id    = aws_apigatewayv2_api.main.id
  route_id = aws_apigatewayv2_route.online.id
  route_response_key = "$default"
}
