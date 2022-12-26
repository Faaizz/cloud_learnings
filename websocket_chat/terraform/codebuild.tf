resource "aws_codebuild_project" "backend" {
  name = local.backend.cb.project_name

  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    type = "LINUX_CONTAINER"
    image = "aws/codebuild/standard:4.0"
    compute_type = "BUILD_GENERAL1_SMALL"

    environment_variable {
      name = "AWS_REGION"
      value = var.aws_region
    }
    environment_variable {
      name = "AWS_ACCOUNT_ID"
      value = local.account_id
    }
    environment_variable {
      name = "IMAGE_REPO_NAME"
      value = local.ecr.repo_name
    }
    environment_variable {
      name = "IMAGE_TAG"
      value = local.ecr.image_name
    }

    privileged_mode = true
  }

  source {
    type = "GITHUB"
    location = local.backend.github.repo_url
    buildspec = file(join("/", [abspath(path.root), "../../common/buildspec/docker_image_to_ecr.yaml"]))
  }
}

resource "null_resource" "trigger_backend_build" {
  depends_on = [
    aws_codebuild_project.backend
  ]

  provisioner "local-exec" {
    environment = {
      AWS_DEFAULT_REGION = var.aws_region
      AWS_ACCESS_KEY_ID = var.aws_access_key_id
      AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
    }

    working_dir = join("/", [abspath(path.root), "../../common/scripts"])
    interpreter = [
      "/bin/bash", "-c"
    ]

    command = <<-EOF
    ./codebuild_build_project.sh ${local.backend.cb.project_name}
    EOF
  }
}
