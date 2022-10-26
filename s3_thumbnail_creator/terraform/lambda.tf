resource "aws_lambda_function" "s3_thumbnail_creator_terraform" {
  function_name = local.lambda_function_name
  # Execution role
  role = aws_iam_role.create_thumbnail_role.arn
  # I'm using an M1 macOS
  architectures = ["arm64"]
  package_type  = "Image"
  image_uri     = local.ecr_image_uri
  publish       = true

  environment {
    variables = {
      DEST_BUCKET = local.destination_bucket_name
    }
  }

  tags = local.uniform_tags

  depends_on = [null_resource.push_docker_image]
}

# Invoke permission for S3 notifications from source bucket
resource "aws_lambda_permission" "allow_invocation_source_bucket" {
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.s3_thumbnail_creator_terraform.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = "arn:aws:s3:::${local.source_bucket_name}"
  source_account = local.account_id
}
