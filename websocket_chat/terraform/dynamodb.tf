resource "aws_dynamodb_table" "main" {
  name = local.backend.dynamodb.name
  billing_mode = "PROVISIONED"
  read_capacity = 1
  write_capacity = 1
  hash_key = "connectionId"

  attribute {
    name = "connectionId"
    type = "S"
  }
}
