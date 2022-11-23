# AWS
variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}
variable "aws_region" {
  default = "eu-central-1"
}

# GitHub
variable "github_access_token" {}
variable "frontend_repository" {
  default = "https://github.com/Faaizz/simple_websocket_chatapp_frontend.git"
}

# Application
variable "websocket_url" {
  default = "wss://wgqv74nka0.execute-api.eu-central-1.amazonaws.com/production"
}
