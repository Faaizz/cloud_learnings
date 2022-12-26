output "app_id" {
  value = aws_amplify_app.chatapp_frontend_app.id
}

output "frontend_url" {
  value = "https://main.${aws_amplify_app.chatapp_frontend_app.default_domain}"
}

output "backend_url" {
  value = "http://${aws_lb.ecs.dns_name}:${local.backend.port}"
}
