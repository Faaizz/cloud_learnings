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
