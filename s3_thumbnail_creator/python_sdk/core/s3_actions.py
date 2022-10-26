from core import session

s3_client = session.client('s3')
s3 = session.resource('s3')

def create_buckets(bucket_names: list[str]) -> None:
  for bucket_name in bucket_names:
    s3.create_bucket(Bucket=bucket_name)

def setup_bucket_notification_on_object_create(source_bucket_name: str, lambda_function_arn: str) -> None:
  bucket_notification = s3.BucketNotification(source_bucket_name)
  bucket_notification.put(
    NotificationConfiguration={
      'LambdaFunctionConfigurations': [
        {
          'LambdaFunctionArn': lambda_function_arn,
          'Events': ['s3:ObjectCreated:*'],
        }
      ],
    }
  )

def delete_buckets(bucket_names: list[str]) -> None:
  for bucket_name in bucket_names:
    # Get bucket objects
    res_data = s3_client.list_objects(
      Bucket=bucket_name,
    )
    delete_list = [ {'Key': bucket_object['Key']} for bucket_object in res_data['Contents']]
    # Delete bucket objects
    s3_client.delete_objects(
      Bucket=bucket_name,
      Delete={
        'Objects': delete_list,
      }
    )
    # Delete bucket
    s3_client.delete_bucket(Bucket=bucket_name)
