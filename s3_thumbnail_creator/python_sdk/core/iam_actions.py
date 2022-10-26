import json

from core import session
from core import uniform_tags
from core import thumbnail_policy_name
from core import thumbnail_role_name
from core import source_bucket_name
from core import destination_bucket_name

iam = session.resource('iam')
iam_client = session.client('iam')

# Documents

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



def create_thumbnail_policy(policy_json: str, policy_name: str):
  """returns policy: boto3.resources.factory.iam.Policy"""
  thumbnail_policy = iam.create_policy(
    PolicyName=policy_name,
    PolicyDocument=policy_json,
    Description='Allow permissions to read source bucket and write destination bucket',
    Tags=uniform_tags,
  )
  return thumbnail_policy

def create_thumbnail_creation_role(trust_policy_json: str, role_name: str):
  """returns role: boto3.resources.factory.iam.Role"""
  thumbnail_role = iam.create_role(
    RoleName=role_name,
    AssumeRolePolicyDocument=trust_policy_json,
    Description='Allow permissions for Lambda to assume role',
    Tags=uniform_tags,
  )
  return thumbnail_role

def main() -> str:
  """returns policy arn and role arn"""
  policy_json = get_read_source_write_destination_s3_bucket_policy_json(source_bucket_name, destination_bucket_name)
  role_trust_policy_json = get_execution_role_trust_policy_json()
  thumbnail_policy = create_thumbnail_policy(policy_json, thumbnail_policy_name)    
  try:
    thumbnail_role =  create_thumbnail_creation_role(role_trust_policy_json, thumbnail_role_name)
  except Exception as e:
    thumbnail_policy.delete()
    raise e

  try:
    iam_client.attach_role_policy(
      RoleName=thumbnail_role.name,
      PolicyArn=thumbnail_policy.arn,
    )
  except Exception as e:
    thumbnail_role.delete()
    raise e

  return thumbnail_policy.arn, thumbnail_role.arn

def detach_policy_from_role(role_name: str, policy_arn: str) -> None:
  iam_client.detach_role_policy(RoleName=role_name, PolicyArn=policy_arn)

def delete_role(role_name: str) -> None:
  iam_client.delete_role(RoleName=role_name)

def delete_policy(policy_arn: str) -> None:
  iam_client.delete_policy(PolicyArn=policy_arn)
