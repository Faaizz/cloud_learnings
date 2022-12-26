terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.35.0, < 4.36.0"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key

  default_tags {
    tags = {
      Class = "websocket-chat-application"
      Environment = "learning"
    }
  }
}
