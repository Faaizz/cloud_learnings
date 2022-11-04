terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.35.0, < 4.36.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}
