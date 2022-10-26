from core import session
from core import uniform_tags
from core import lambda_function_name
from core import source_bucket_name
from core import account_id

lambda_client = session.client('lambda')

def main(ecr_image_uri: str, role_arn: str, env_vars: dict):
  """returns lambda function arn"""
  # Lambda takes only a single dict for Tags
  lambda_uniform_tags = {tag['Key']: tag['Value'] for tag in uniform_tags}

  # Create function
  thumbnail_creation_lambda = lambda_client.create_function(
    FunctionName=lambda_function_name,
    PackageType='Image',
    Code={'ImageUri': ecr_image_uri},
    Publish=True,
    Role=role_arn,
    Architectures=['arm64'],
    Environment={
      'Variables': env_vars,
    },
    Tags=lambda_uniform_tags,
  )

  # GOTCHA: Wait till function is active. 
  # S3 notification fails wth "Unable to validate the following destination configurations" otherwise
  waiter = lambda_client.get_waiter('function_active')
  waiter.wait(
    FunctionName=lambda_function_name,
    WaiterConfig={
        'Delay': 5,
        'MaxAttempts': 60,
    }
  )
  
  # Allow S3 to invoke lambda
  lambda_client.add_permission(
    FunctionName=lambda_function_name,
    StatementId='statement' + lambda_function_name + source_bucket_name,
    Action='lambda:InvokeFunction',
    Principal='s3.amazonaws.com',
    SourceArn='arn:aws:s3:::{}'.format(source_bucket_name),
    SourceAccount=account_id,
  )

  return thumbnail_creation_lambda['FunctionArn']

def delete_function(function_name: str) -> None:
  lambda_client.delete_function(FunctionName=function_name)
