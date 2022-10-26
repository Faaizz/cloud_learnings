# Source Bucket
resource "aws_s3_bucket" "source_bucket" {
  bucket = local.source_bucket_name
  force_destroy = true
}
locals {
  source_bucket_arn = aws_s3_bucket.source_bucket.arn
}

# Setup object create notification for source bucket
resource "aws_s3_bucket_notification" "invoke_create_thumbnail_lambda" {
  bucket = aws_s3_bucket.source_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_thumbnail_creator_terraform.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_invocation_source_bucket]
}

# Destination Bucket
resource "aws_s3_bucket" "destination_bucket" {
  bucket = local.destination_bucket_name
  force_destroy = true
}
locals {
  destination_bucket_arn = aws_s3_bucket.destination_bucket.arn
}
