resource "aws_amplify_app" "chatapp_frontend_app" {
  name = "websocket_chatapp_frontend"
  repository = local.frontend.github.repo_url
  access_token = var.github_access_token

  build_spec = <<-EOF
    version: 0.1
    frontend:
      phases:
        preBuild:
          commands:
            - echo installing dependencies
            - npm install
        build:
          commands:
            - echo build started on `date`
            - echo compiling javascript
            - npm run build
      artifacts:
        baseDirectory: out
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOF

  environment_variables = {
    WEBSOCKET_URL = aws_apigatewayv2_stage.dev.invoke_url
  }

  # The default rewrites and redirects added by the Amplify Console.
  custom_rule {
    source = "/<*>"
    status = "404"
    target = "/index.html"
  }
}

resource "aws_amplify_branch" "main" {
  # Adds webhooks on the GitHub repository and does not delete them on terraform destroy
  app_id      = aws_amplify_app.chatapp_frontend_app.id
  branch_name = "main"

  #  deploy frontend
  provisioner "local-exec" {
    environment = {
      AWS_DEFAULT_REGION = var.aws_region
      AWS_ACCESS_KEY_ID = var.aws_access_key_id
      AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
      APP_ID = aws_amplify_app.chatapp_frontend_app.id
      BRANCH_NAME = "main"
    }

    working_dir = join("/", [abspath(path.root), "scripts"])
    interpreter = [
      "/bin/bash", "-c"
    ]

    command = <<-EOF
    ./deploy_frontend.sh
    EOF
  }
}
