import subprocess
import base64

from core import session
from core import uniform_tags
from core import account_id
from core import aws_region_name
from core import ecr_repo_name
from core import ecr_image_name

ecr_client = session.client('ecr')

def main(app_path: str) -> str:
  """returns ecr image uri"""
  # Create Repo
  ecr_client.create_repository(
    repositoryName=ecr_repo_name,
    tags=uniform_tags,
  )

  # Fetch Authentication data
  auth_data = ecr_client.get_authorization_token()['authorizationData']
  auth_token_encoded = auth_data[0]['authorizationToken']
  auth_user_and_token = base64.b64decode(auth_token_encoded).decode('utf-8')
  auth_token = auth_user_and_token.split(':')[1]

  # Construct image tag
  ecr_image_uri = '{}.dkr.ecr.{}.amazonaws.com/{}:{}'.format(account_id, aws_region_name, ecr_repo_name, ecr_image_name)

  # Build image
  subprocess.run('docker build -t {} {}'.format(ecr_image_uri, app_path), shell=True)

  # Login and push image
  subprocess.run('echo {} | docker login --username AWS --password-stdin {}.dkr.ecr.{}.amazonaws.com && docker push {}'.format(auth_token, account_id, aws_region_name, ecr_image_uri), shell=True)

  # Image URI
  return ecr_image_uri

def delete_repo(repo_name: str) -> None:
  # Delete images
  ecr_client.batch_delete_image(
    repositoryName=repo_name,
    imageIds=ecr_client.list_images(repositoryName=repo_name)['imageIds']
  )
  # Delete repo
  ecr_client.delete_repository(repositoryName=repo_name)
