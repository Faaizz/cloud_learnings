resource "aws_iam_role" "task" {
  name = local.ecs.task.role.name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["sts:AssumeRole"]
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        } 
      }
    ]
  })

}

resource "aws_iam_policy" "task" {
  name = local.ecs.task.role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "DynamoDBTableAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:ConditionCheckItem",
          "dynamodb:PutItem",
          "dynamodb:DescribeTable",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.main.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task" {
  role = aws_iam_role.task.name
  policy_arn = aws_iam_policy.task.arn
}

# ECS task execution role
resource "aws_iam_role" "task_exec" {
  name = local.ecs.task.exec_role.name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["sts:AssumeRole"]
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "task_exec" {
  name = local.ecs.task.exec_role.name
  description = "Allow access to CloudWatch Logs and ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_exec" {
  role = aws_iam_role.task_exec.name
  policy_arn = aws_iam_policy.task_exec.arn
}

# CodeBuild service role
resource "aws_iam_role" "codebuild" {
  name = local.backend.cb.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["sts:AssumeRole"]
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "codebuild" {
  name = local.backend.cb.role_name
  description = "Allow access to CloudWatch Logs and ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_to_role" {
  role = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
}
