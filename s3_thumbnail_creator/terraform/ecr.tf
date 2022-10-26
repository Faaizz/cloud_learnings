# Authorization token
data "aws_ecr_authorization_token" "ecr_auth_info" {}

resource "aws_ecr_repository" "my_repo_terraform" {
  name = local.ecr_repo_name
  # Forcefully delete all images to facilitate destroy
  force_delete = true

  tags = local.uniform_tags
}

resource "docker_image" "s3_thumbnail_creator" {
  name = local.docker_image_name
  build {
    path = local.app_path
    tag  = [local.ecr_image_uri]
  }
  depends_on = [aws_ecr_repository.my_repo_terraform, null_resource.pull_source_code]
}

# Provisioner usage:
#   Untypical of Terraform IaC concepts, but required here to push image.
#   The risks are "mitigated" by enabling "force_delete" on the ECR Repo.
resource "null_resource" "pull_source_code" {
  provisioner "local-exec" {
    command = <<-EOF
      $(mkdir ${local.src_path} || true) && \
      cd ${local.src_path} && \
      git clone ${local.github_repo_url}
    EOF
  }
}

resource "null_resource" "push_docker_image" {
  depends_on = [docker_image.s3_thumbnail_creator, data.aws_ecr_authorization_token.ecr_auth_info]

  provisioner "local-exec" {
    command = <<-EOF
    echo ${data.aws_ecr_authorization_token.ecr_auth_info.password} | \
    docker login --username ${data.aws_ecr_authorization_token.ecr_auth_info.user_name} \
    --password-stdin ${local.ecr_repo_uri} && \
    docker push ${local.ecr_image_uri}
    EOF
  }
}
