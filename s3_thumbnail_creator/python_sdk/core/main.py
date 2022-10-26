import os
import json

from core import source_bucket_name
from core import destination_bucket_name
from core import lambda_function_name
from core import thumbnail_role_name
from core import ecr_repo_name
from core import src_path
from core import app_path
from core import repo_url
from core import cleanup_file_path

from core import git_actions
from core import s3_actions
from core import iam_actions
from core import ecr_actions
from core import lambda_actions
from core import logger


def main():
  # Pull Source Code
  git_actions.pull_source_code(repo_url, src_path)

  # Create buckets
  s3_actions.create_buckets([source_bucket_name, destination_bucket_name])

  # Setup Permissions and Role
  thumbnail_policy_arn, thumbnail_role_arn = iam_actions.main()
  logger.info(thumbnail_role_arn)

  # Build and publish image to ECR
  ecr_image_uri = ecr_actions.main(app_path)
  logger.info(ecr_image_uri)

  # Create Lambda Function
  env_vars = {
    'DEST_BUCKET': destination_bucket_name,
  }
  lambda_function_arn = lambda_actions.main(ecr_image_uri, thumbnail_role_arn, env_vars)
  logger.info(lambda_function_arn)

  # Setup S3 bucket notifications to invoke lambda function on object create
  s3_actions.setup_bucket_notification_on_object_create(source_bucket_name, lambda_function_arn)

  # Save resource information for cleanup
  cleanup_data = {
    'source_bucket_name': source_bucket_name,
    'destination_bucket_name': destination_bucket_name,
    'lambda_function_name': lambda_function_name,
    'thumbnail_role_name': thumbnail_role_name,
    'thumbnail_policy_arn': thumbnail_policy_arn,
    'ecr_repo_name': ecr_repo_name,
  }
  with open(cleanup_file_path, 'w') as cleanup_f:
    json.dump(cleanup_data, cleanup_f)
