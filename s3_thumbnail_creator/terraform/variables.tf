# Github Credentials
variable github_user {}
variable github_pat {}
variable github_repo {}

# AWS Credentials
variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}
variable "aws_region" {
  default = "us-east-1"
}

resource "random_integer" "bucket_suffix" {
  min = 5000
  max = 9000
}

locals {
  github_repo_url = "https://${var.github_user}:${var.github_pat}@github.com/${var.github_user}/${var.github_repo}"

  uniform_tags = {
    Class = "s3-thumbnail-creator-terraform"
  }

  source_bucket_name = "source-s3-thumbnail-bucket-${random_integer.bucket_suffix.result}-terraform"

  destination_bucket_name = "destination-s3-thumbnail-bucket-${random_integer.bucket_suffix.result}-terraform"

  src_path = join("", [abspath(path.root), "/src"])
  app_path = join("", [local.src_path, "/", var.github_repo])

  thumbnail_policy_name = "thumbnail_policy_terraform"
  thumbnail_role_name   = "thumbnail_role_terraform"
  lambda_function_name  = "s3_thumbnail_creator_terraform"
  ecr_repo_name         = "my_repo_terraform"
  ecr_image_name        = "s3_thumbnail_creator_terraform"
  docker_image_name     = "s3_thumbnail_creator_docker_terraform"

  account_id = data.aws_caller_identity.current.account_id

  ecr_repo_uri  = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  ecr_image_uri = "${local.ecr_repo_uri}/${local.ecr_repo_name}:${local.ecr_image_name}"
}
