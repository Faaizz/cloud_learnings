import os
import random
import logging
import boto3

# Configure logging
logging.basicConfig(format='%(asctime)s %(message)s')
logger = logging.getLogger(__package__)
logger.setLevel(logging.INFO)

# Module
__basefilepath__ = os.path.dirname(os.path.abspath(__file__) + "/")

# Some Constants
# Source code
repo_url = 'https://github.com/Faaizz/s3_thumbnail_creator'

# AWS
uniform_tags = [{
  'Key': 'Group',
  'Value': 's3_thumbnail_creator_python',
}]
cleanup_file_path = os.getcwd() + '/cleanupdata.json'
source_bucket_name = 'source-s3-thumbnail-bucket-{}'.format(random.randint(5000, 9000))
destination_bucket_name = 'destination-s3-thumbnail-bucket-{}'.format(random.randint(5000, 9000))
thumbnail_policy_name = 'thumbnail_policy'
thumbnail_role_name = 'thumbnail_role'
lambda_function_name = 's3_thumbnail_creator'
ecr_repo_name = 'my_repo'
ecr_image_name = 's3_thumbnail_creator'
codebuild_project_name = 's3_thumbnail_creator_project'
codebuild_policy_name = 'codebuild_policy'
codebuild_role_name = 'codebuild_role'


# AWS Auth Info
aws_region_name = os.environ['AWS_DEFAULT_REGION']
aws_access_key_id = os.environ['AWS_ACCESS_KEY_ID']
aws_secret_access_key = os.environ['AWS_SECRET_ACCESS_KEY']

# Get Session
session = boto3.Session(
  aws_access_key_id=aws_access_key_id,
  aws_secret_access_key=aws_secret_access_key,
  region_name=aws_region_name,
)

# Account Information
account_id = session.client('sts').get_caller_identity()['Account']
