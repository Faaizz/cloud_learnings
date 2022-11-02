import time

from core import session

cb_client = session.client('codebuild')

def create_project(
    codebuild_role_arn: str, 
    uniform_tags: list[object],
    repo_url: str,
    aws_region_name: str,
    account_id: str,
    ecr_repo_name: str,
    ecr_image_name: str,
    codebuild_project_name: str,
  ) -> str:
  # create build project
  proj_res = cb_client.create_project(
    name=codebuild_project_name,
    source={
      'type': 'GITHUB',
      'location': repo_url,
      # 'auth': {
      #   'type': 'OAUTH',
      # },
    },
    artifacts={
      'type': 'NO_ARTIFACTS',
    },
    environment={
      'type': 'LINUX_CONTAINER',
      'image': 'aws/codebuild/standard:4.0',
      'computeType': 'BUILD_GENERAL1_SMALL',
      'environmentVariables': [
        {
          'name': 'AWS_DEFAULT_REGION',
          'value': aws_region_name,
          'type': 'PLAINTEXT',
        },
        {
          'name': 'AWS_ACCOUNT_ID',
          'value': account_id,
          'type': 'PLAINTEXT',
        },
        {
          'name': 'IMAGE_REPO_NAME',
          'value': ecr_repo_name,
          'type': 'PLAINTEXT',
        },
        {
          'name': 'IMAGE_TAG',
          'value': ecr_image_name,
          'type': 'PLAINTEXT',
        },
      ],
      'privilegedMode': True,
    },
    serviceRole=codebuild_role_arn,
    tags=[{'key': item['Key'], 'value': item['Value']} for item in uniform_tags],
  )

  return proj_res['project']['name']

def build_project(name: str) -> None:
  """
  returns image URI
  """
  build_res = cb_client.start_build(
    projectName=name,
  )
  build_id = build_res['build']['id']

  # wait for build to complete
  build_success = False
  for _ in range(0, 20):
    time.sleep(15)
    build = cb_client.batch_get_builds(ids=[build_id])
    build_status = build['builds'][0]['buildStatus']
    if build_status == 'SUCCEEDED':
      return

  if not build_success:
    raise Exception('build failed')

def main(
  codebuild_role_arn: str, 
  uniform_tags: list[object],
  repo_url: str,
  aws_region_name: str,
  account_id: str,
  ecr_repo_name: str,
  ecr_image_name: str,
  codebuild_project_name: str,
) -> str:
  """
  returns image URI
  """
  build_project(create_project(
    codebuild_role_arn, 
    uniform_tags,
    repo_url,
    aws_region_name,
    account_id,
    ecr_repo_name,
    ecr_image_name,
    codebuild_project_name,
  ))

  image_uri = '{}.dkr.ecr.{}.amazonaws.com/{}:{}'.format(account_id, aws_region_name, ecr_repo_name, ecr_image_name)
  return image_uri

def delete_project(proj_name: str) -> None:
  # delete builds
  all_build_ids = cb_client.list_builds_for_project(
    projectName=proj_name,
  )['ids']
  cb_client.batch_delete_builds(ids=all_build_ids)
  # delete project
  cb_client.delete_project(name=proj_name)
