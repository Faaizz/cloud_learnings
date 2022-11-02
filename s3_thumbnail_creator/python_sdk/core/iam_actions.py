import json

from core import session
from core import uniform_tags

iam = session.resource('iam')
iam_client = session.client('iam')

def get_codebuild_service_role_policy_json() -> str:
  codebuild_service_role_policy_dict = {
    'Version': '2012-10-17',
    'Statement': [
      {
        'Effect': 'Allow',
        'Action': [
          'logs:CreateLogGroup',
          'logs:CreateLogStream',
          'logs:PutLogEvents',
        ],
        'Resource': 'arn:aws:logs:*:*:*',
      },
      {
        'Effect': 'Allow',
        'Action': [
          'ecr:BatchCheckLayerAvailability',
          'ecr:CompleteLayerUpload',
          'ecr:GetAuthorizationToken',
          'ecr:InitiateLayerUpload',
          'ecr:PutImage',
          'ecr:UploadLayerPart',
        ],
        'Resource': '*',
      },
    ],
  }
  return json.dumps(codebuild_service_role_policy_dict)

def get_codebuild_service_role_trust_policy_json() -> str:
  codebuild_service_role_trust_policy_dict = {
    'Version': '2012-10-17',
    'Statement': [
      {
        'Effect': 'Allow',
        'Action': [
          'sts:AssumeRole',
        ],
        'Principal': {
          'Service': [
            'codebuild.amazonaws.com',
          ],
        },
      },
    ],
  }
  return json.dumps(codebuild_service_role_trust_policy_dict)

def get_execution_role_trust_policy_json() -> str:
  exec_role_trust_policy_dict = {
    'Version': '2012-10-17',
    'Statement': [
      {
        'Effect': 'Allow',
        'Action': [
          'sts:AssumeRole',
        ],
        'Principal': {
          'Service': [
            'lambda.amazonaws.com',
          ]
        },
      },
    ],
  }
  exec_role_trust_policy_json = json.dumps(exec_role_trust_policy_dict)
  return exec_role_trust_policy_json

def get_read_source_write_destination_s3_bucket_policy_json(source_bucket_name: str, destination_bucket_name: str) -> str:
  read_source_write_destination_s3_bucket_policy_dict = {
    'Version': '2012-10-17',
    'Statement': [
      {
        'Effect': 'Allow',
        'Action': [
          'logs:CreateLogGroup',
          'logs:CreateLogStream',
          'logs:PutLogEvents'
        ],
        'Resource': 'arn:aws:logs:*:*:*'
      },
      {
        'Effect': 'Allow',
        'Action': [
          's3:GetObject'
        ],
        'Resource': 'arn:aws:s3:::{}/*'.format(source_bucket_name),
      },
      {
        'Effect': 'Allow',
        'Action': [
          's3:PutObject'
        ],
        'Resource': 'arn:aws:s3:::{}/*'.format(destination_bucket_name),
      }
    ]
  }
  read_source_write_destination_s3_bucket_policy_json = json.dumps(read_source_write_destination_s3_bucket_policy_dict)
  return read_source_write_destination_s3_bucket_policy_json

def create_policy(policy_json: str, policy_name: str, uniform_tags: list[object]):
  """returns policy: boto3.resources.factory.iam.Policy"""
  thumbnail_policy = iam.create_policy(
    PolicyName=policy_name,
    PolicyDocument=policy_json,
    Description='Allow permissions to read source bucket and write destination bucket',
    Tags=uniform_tags,
  )
  return thumbnail_policy

def create_role(trust_policy_json: str, role_name: str, uniform_tags: list[object]):
  """returns role: boto3.resources.factory.iam.Role"""
  thumbnail_role = iam.create_role(
    RoleName=role_name,
    AssumeRolePolicyDocument=trust_policy_json,
    Description='Allow permissions for Lambda to assume role',
    Tags=uniform_tags,
  )
  return thumbnail_role

def main(thumbnail_policy_name: str, thumbnail_role_name: str, source_bucket_name: str, destination_bucket_name: str, codebuild_policy_name: str, codebuild_role_name: str, uniform_tags: list[object]) -> tuple[str]:
  """returns thumbnail_policy.arn, thumbnail_role.arn, codebuild_policy.arn, codebuild_role.arn"""
  # codebuild policy and role
  policy_json = get_codebuild_service_role_policy_json()
  role_trust_policy_json = get_codebuild_service_role_trust_policy_json()
  codebuild_policy = create_policy(policy_json, codebuild_policy_name, uniform_tags)
  try:
    codebuild_role = create_role(role_trust_policy_json, codebuild_role_name, uniform_tags)
  except Exception as e:
    codebuild_policy.delete()
    raise e

  try:
    iam_client.attach_role_policy(
      RoleName=codebuild_role.name,
      PolicyArn=codebuild_policy.arn,
    )
  except Exception as e:
    codebuild_policy.delete()
    codebuild_role.delete()
    raise e
  
  # thumbnail policy and role
  policy_json = get_read_source_write_destination_s3_bucket_policy_json(source_bucket_name, destination_bucket_name)
  role_trust_policy_json = get_execution_role_trust_policy_json()
  thumbnail_policy = create_policy(policy_json, thumbnail_policy_name, uniform_tags)    
  try:
    thumbnail_role =  create_role(role_trust_policy_json, thumbnail_role_name, uniform_tags)
  except Exception as e:
    thumbnail_policy.delete()
    raise e

  try:
    iam_client.attach_role_policy(
      RoleName=thumbnail_role.name,
      PolicyArn=thumbnail_policy.arn,
    )
  except Exception as e:
    thumbnail_policy.delete()
    thumbnail_role.delete()
    raise e

  return thumbnail_policy.arn, thumbnail_role.arn, codebuild_policy.arn, codebuild_role.arn

def detach_policy_from_role(role_name: str, policy_arn: str) -> None:
  iam_client.detach_role_policy(RoleName=role_name, PolicyArn=policy_arn)

def delete_role(role_name: str) -> None:
  iam_client.delete_role(RoleName=role_name)

def delete_policy(policy_arn: str) -> None:
  iam_client.delete_policy(PolicyArn=policy_arn)
