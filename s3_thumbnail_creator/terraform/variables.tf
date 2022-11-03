# Github
variable github_repo_url {
  default = "https://github.com/Faaizz/s3_thumbnail_creator"

}

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
  uniform_tags = {
    Class = "s3-thumbnail-creator-terraform"
  }

  source_bucket_name = "source-s3-thumbnail-bucket-${random_integer.bucket_suffix.result}-terraform"

  destination_bucket_name = "destination-s3-thumbnail-bucket-${random_integer.bucket_suffix.result}-terraform"

  thumbnail_policy_name = "thumbnail_policy_terraform"
  thumbnail_role_name   = "thumbnail_role_terraform"
  lambda_function_name  = "s3_thumbnail_creator_terraform"
  ecr_repo_name         = "my_repo_terraform"
  ecr_image_name        = "s3_thumbnail_creator_terraform"
  docker_image_name     = "s3_thumbnail_creator_docker_terraform"
  codebuild_project_name = "s3_thumbnail_creator_project"
  codebuild_policy_name = "codebuild_policy_terraform"
  codebuild_role_name = "codebuild_role_terraform"

  account_id = data.aws_caller_identity.current.account_id

  ecr_image_uri = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.ecr_repo_name}:${local.ecr_image_name}"
}
