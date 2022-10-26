import json

from core import cleanup_file_path
from core import logger

from core import s3_actions
from core import iam_actions
from core import lambda_actions
from core import ecr_actions

if __name__ == '__main__':
  with open(cleanup_file_path) as cleanup_f:
    cleanup_data = json.load(cleanup_f)

  # S3 Buckets
  s3_actions.delete_buckets([cleanup_data['source_bucket_name'], cleanup_data['destination_bucket_name']])
  # Lambda function
  lambda_actions.delete_function(cleanup_data['lambda_function_name'])
  # IAM: Role and Policy
  iam_actions.detach_policy_from_role(cleanup_data['thumbnail_role_name'], cleanup_data['thumbnail_policy_arn'])
  iam_actions.delete_role(cleanup_data['thumbnail_role_name'])
  iam_actions.delete_policy(cleanup_data['thumbnail_policy_arn'])
  # ECR
  ecr_actions.delete_repo(cleanup_data['ecr_repo_name'])

  logger.info('finished cleanup')
