resource "aws_ecr_repository" "this" {
  name = local.ecr.repo_name
  force_delete = true
}
