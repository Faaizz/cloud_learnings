from core import session

ecr_client = session.client('ecr')

def main(ecr_repo_name: str, uniform_tags: list[object]) -> str:
  """returns ecr image uri"""
  # Create Repo
  ecr_client.create_repository(
    repositoryName=ecr_repo_name,
    tags=uniform_tags,
  )

def delete_repo(repo_name: str) -> None:
  # Delete images
  ecr_client.batch_delete_image(
    repositoryName=repo_name,
    imageIds=ecr_client.list_images(repositoryName=repo_name)['imageIds']
  )
  # Delete repo
  ecr_client.delete_repository(repositoryName=repo_name)
