resource "aws_codebuild_project" "thumbnail_creation_image_build" {
  name = local.codebuild_project_name
  service_role = aws_iam_role.codebuild_service_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    type = "LINUX_CONTAINER"
    image = "aws/codebuild/standard:4.0"
    compute_type = "BUILD_GENERAL1_SMALL"

    environment_variable {
      name = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
    environment_variable {
      name = "AWS_ACCOUNT_ID"
      value = local.account_id
    }
    environment_variable {
      name = "IMAGE_REPO_NAME"
      value = local.ecr_repo_name
    }
    environment_variable {
      name = "IMAGE_TAG"
      value = local.ecr_image_name
    }

    privileged_mode = true
  }

  source {
    type = "GITHUB"
    location = var.github_repo_url
  }

  tags = local.uniform_tags
}

resource "null_resource" "trigger_build" {
  depends_on = [
    aws_codebuild_project.thumbnail_creation_image_build
  ]
  
  provisioner "local-exec" {
    environment = {
      AWS_DEFAULT_REGION = var.aws_region
      AWS_ACCESS_KEY_ID = var.aws_access_key_id
      AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
    }

    working_dir = join("/", [abspath(path.root), "scripts"])
    interpreter = [
      "/bin/bash", "-c"
    ]

    command = <<-EOF
    ./build.sh ${local.codebuild_project_name}
    EOF
  }
}
