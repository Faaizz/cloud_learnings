# Authorization token
data "aws_ecr_authorization_token" "ecr_auth_info" {}

resource "aws_ecr_repository" "my_repo_terraform" {
  name = local.ecr_repo_name
  # Forcefully delete all images to facilitate destroy
  force_delete = true

  tags = local.uniform_tags
}
