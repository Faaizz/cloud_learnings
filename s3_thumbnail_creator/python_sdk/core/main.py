import time
import json

from core import aws_region_name
from core import account_id
from core import source_bucket_name
from core import destination_bucket_name
from core import lambda_function_name
from core import thumbnail_policy_name
from core import thumbnail_role_name
from core import codebuild_policy_name
from core import codebuild_role_name
from core import ecr_repo_name
from core import ecr_image_name
from core import codebuild_project_name
from core import repo_url
from core import cleanup_file_path
from core import uniform_tags

from core import s3_actions
from core import iam_actions
from core import ecr_actions
from core import lambda_actions
from core import codebuild_actions
from core import logger


def main():
  # Time execution
  start_time = time.time()

  # Create buckets
  s3_actions.create_buckets([source_bucket_name, destination_bucket_name])

  # Setup Permissions and Role
  thumbnail_policy_arn, thumbnail_role_arn, codebuild_policy_arn, codebuild_role_arn = iam_actions.main(
    thumbnail_policy_name,
    thumbnail_role_name,
    source_bucket_name,
    destination_bucket_name,
    codebuild_policy_name,
    codebuild_role_name,
    uniform_tags,
  )
  logger.info(thumbnail_role_arn)
  # wait for role trust permissions to propagate
  # a wierd error of: "CodeBuild is not authorized to perform: sts:AssumeRole on arn:aws:iam::<account_id>:role/codebuild_role" is returned if this sleep timer is not introduced
  time.sleep(10)

  # Create ECR repository
  ecr_actions.main(ecr_repo_name, uniform_tags)
  
  # Build and publish image to ECR repository
  ecr_image_uri = codebuild_actions.main(
    codebuild_role_arn, 
    uniform_tags,
    repo_url,
    aws_region_name,
    account_id,
    ecr_repo_name,
    ecr_image_name,
    codebuild_project_name,
  )
  logger.info(ecr_image_uri)

  # Create Lambda Function
  env_vars = {
    'DEST_BUCKET': destination_bucket_name,
  }
  lambda_function_arn = lambda_actions.main(
    ecr_image_uri, 
    thumbnail_role_arn, 
    env_vars,
    uniform_tags,
    lambda_function_name,
    source_bucket_name,
    account_id,
  )
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
    'codebuild_project_name': codebuild_project_name,
    'codebuild_role_name': codebuild_role_name,
    'codebuild_policy_arn': codebuild_policy_arn,
  }
  with open(cleanup_file_path, 'w') as cleanup_f:
    json.dump(cleanup_data, cleanup_f)

  logger.info('execution took: {} seconds'.format(time.time() - start_time))
