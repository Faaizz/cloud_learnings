# Policy to allow CodeBuild access to CloudWatch Logs
#   and access to ECR to perform image-related functions
resource "aws_iam_policy" "codebuild_service_policy" {
  name = local.codebuild_policy_name
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

  tags = local.uniform_tags
}

# CodeBuild service role
resource "aws_iam_role" "codebuild_service_role" {
  name = local.codebuild_role_name
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

  tags = local.uniform_tags
}

# CodeBuild: associate policy with service role
resource "aws_iam_role_policy_attachment" "codebuild_policy_to_role" {
  role = aws_iam_role.codebuild_service_role.name
  policy_arn = aws_iam_policy.codebuild_service_policy.arn
}

# Policy to allow read access to source bucket 
#   and write access to destination bucket.
# Also allows access to CloudWatch Logs
resource "aws_iam_policy" "create_thumbnail_policy" {
  name        = local.thumbnail_policy_name
  description = "Allow read access to source bucket and write access to destination bucket"

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
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${local.source_bucket_arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${local.destination_bucket_arn}/*"
      },
    ]
  })

  tags = local.uniform_tags
}

# Thumbnail Creation Lambda Execution Role
resource "aws_iam_role" "create_thumbnail_role" {
  name = local.thumbnail_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["sts:AssumeRole"]
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = local.uniform_tags
}

# Associate Policy with Role
resource "aws_iam_role_policy_attachment" "create_thumbnail_policy_to_role" {
  role   = aws_iam_role.create_thumbnail_role.name
  policy_arn = aws_iam_policy.create_thumbnail_policy.arn
}
