# 3xImplementation: S3 Thumbnail Creator

This is the first in a series of episodes that compares three different implementations of basic architectures in AWS. In this episode, implementations of an "S3 Thumbnail Creator" in Terraform, AWS CloudFormation, and AWS Python SDK (boto3) are weighed up.

The source code for this episode can be found on GitHub: [https://github.com/Faaizz/cloud_learnings/tree/main/s3_thumbnail_creator](https://github.com/Faaizz/cloud_learnings/tree/main/s3_thumbnail_creator).

## Architecture
The S3 Thumbnail Creator is a serverless application that automatically generates thumbnails of images uploaded in one S3 bucket (Source bucket) and saves them in another S3 bucket (Destination bucket).
A basic layout is shown below. The green arrows show the deployment flow, while the black arrows show the operation flow.
![architecture](./docs/architecture.png)

## Resources
A few AWS resources are required for this application and its deployment.

First, we have two S3 buckets, the Source bucket and the Destination bucket.

Then, there's the Lambda function that holds the thumbnail generation logic, whose source code lives in a [GitHub repository](https://github.com/Faaizz/s3_thumbnail_creator.git).

An ECR repository is created to hold the container image, and a CodeBuild project is used to build the image and push it to ECR.

For the CloudFormation implementation, an extra Lambda function is needed for the Macro that generates S3 bucket names.

![resources](./docs/resources.png)


## Some Notes
* For the CloudFormation implementation, the stacks must be provisioned in some way, this is achieved with minimal [`go` scripts](./cloudformation/) utilizing the AWS Go SDK.
* As the application is not embedded within a CI/CD system, the "build" step requires an external trigger.
For the Terraform implementation, a `provisioner` block is used (I know, using provisioners is (usually) bad practice :-X);
the Python SDK implementation does this from the `python` scripts that make the API calls; 
and the CloudFormation implementation incorporates this in its `go` scripts.

## Implementation
### ECR Repository
The most independent resource of the entire stack is the ECR repository.
It does not require information from any other resource for its creation.
Below is the creation of the ECR repository in all 3 implementations:
```h
# Terraform
resource "aws_ecr_repository" "my_repo_terraform" {
  name = local.ecr_repo_name
  # Forcefully delete all images to facilitate destroy
  force_delete = true

  tags = local.uniform_tags
}
```
```yaml
# CloudFormation
...
Resources:
  ThumbnailCreatorECRRepository:
    Type: AWS::ECR::Repository
...
```
```python
# Python SDK
ecr_client = boto3.client('ecr')
ecr_client.create_repository(
  repositoryName=ecr_repo_name,
  tags=uniform_tags,
)
```

### CodeBuild Project and Build
A CodeBuild project is used to package the thumbnail generation lambda function source code as a container image.To do this, the CodeBuild project requires a service role with permissions to write to CloudWatch logs and push images to ECR. 

**Permissions**

Specifying IAM permissions is basic JSON (or YAML), so realization across all 3 implementation is quite trivial. For the sake of completion, excerpts of the CodeBuild project's service role (and its attached policy) are provided in the following.

For the terraform implementation, the built-in `jsonencode()` function came in handy. The policy and role are created separately, and associated together using the `aws_iam_role_policy_attachment` resource.
```h
# Terraform
resource "aws_iam_policy" "codebuild_service_policy" {
  name = local.codebuild_policy_name
  description = "Allow access to CloudWatch Logs and ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
        ]
        Resource = "*"
      },
    ]
  })

  tags = local.uniform_tags
}

# CodeBuild service role
resource "aws_iam_role" "codebuild_service_role" {
  name = local.codebuild_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["sts:AssumeRole"]
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = local.uniform_tags
}

# CodeBuild: associate policy with service role
resource "aws_iam_role_policy_attachment" "codebuild_policy_to_role" {
  role = aws_iam_role.codebuild_service_role.name
  policy_arn = aws_iam_policy.codebuild_service_policy.arn
}
```

For CloudFormation, the policy is embedded directly into the `Policies` field of the role.
```yaml
# CloudFormation
...
Resources:
  ThumbnailCreationBuildRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Action:
              - 'sts:AssumeRole'
            Principal:
              Service:
                - 'codebuild.amazonaws.com'
      Policies:
        - PolicyName: RandomBucketNameLambdaPolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Sid: CloudWatchLogsAccess
                Action:
                  - 'logs:CreateLogGroup'
                  - 'logs:CreateLogStream'
                  - 'logs:PutLogEvents'
                Resource: 'arn:aws:logs:*:*:*'
              - Effect: Allow
                Sid: ECRAccess
                Action:
                  - 'ecr:BatchCheckLayerAvailability'
                  - 'ecr:CompleteLayerUpload'
                  - 'ecr:GetAuthorizationToken'
                  - 'ecr:InitiateLayerUpload'
                  - 'ecr:PutImage'
                  - 'ecr:UploadLayerPart'
                Resource: '*'
...
```

The python implementation is a little bit more verbose because of reuseable functions, so it'll be skipped.


**Project**

The CodeBuild project's `buildspec.yaml` is included with the Thumbnail Generation lambda source code and is provided below.
```yaml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  build:
    commands:
      - echo Build statred at `date`
      - echo Building Docker image
      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
  post_build:
    commands:
      - echo Build completed at `date`
      - echo Pushing image to ECR repo...
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
```
The build steps are quite simple, and all the required data is provided via environment variables.
The pre-build step logs into the ECR repository.
The actual build step builds the docker image and tags it accordingly.
And in the post-build stage, the image is pushed to the ECR repository.

Across the three implementations, the CodeBuild project was fairly easy to set up.

Since no artifact is produced---the docker image is not considered an artifact by CodeBuild, it is pushed to ECR as a part of the build---the major focus is on properly setting up the environment.
A `LINUX_CONTAINER` build environment type with a standard CodeBuild image (`aws/codebuild/standard:4.0`) is used. `privilege_mode` is enabled (to use docker in docker--`dind`) and the required authentication & tagging data are passed to the build environment via environment variables.
The source is specified as a GitHub repository located at [https://github.com/Faaizz/cloud_learnings/tree/main/s3_thumbnail_creator](https://github.com/Faaizz/cloud_learnings/tree/main/s3_thumbnail_creator).

*At the time of this writing, according to the [CloudFormation documentation]() if the source code is a GitHub repository, "You must connect your AWS account to your GitHub account". This I've found to be inaccurate for a public GitHub repository (as used in this project). As the CodeBuild project could clone the public GitHub repository without having to connect a GitHub account.*


**Triggering the Build**

Once the CodeBuild project is created, a build needs to be triggered, such that the thumbnail generation lambda image is built and pushed to ECR.

In terraform, this is done using a `null_resource` with a provisioner block to trigger a bash script with the CodeBuild project name as an argument.
```h
# Terraform
resource "null_resource" "trigger_build" {
  depends_on = [
    aws_codebuild_project.thumbnail_creation_image_build
  ]

  provisioner "local-exec" {
    environment = {
      AWS_DEFAULT_REGION = var.aws_region
      AWS_ACCESS_KEY_ID = var.aws_access_key_id
      AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
    }

    working_dir = join("/", [abspath(path.root), "scripts"])
    interpreter = [
      "/bin/bash", "-c"
    ]

    command = <<-EOF
    ./build.sh ${local.codebuild_project_name}
    EOF
  }
}
```

The bash scripts uses AWS CLI to trigger a build on the CodeBuild project and waits (for a maximum of 5 minutes) for the build to succeed.
```bash
#!/bin/bash
# ./build.sh

BUILD_ID=$(aws codebuild start-build --project-name $1 | jq -r '.build.id')
echo $BUILD_ID

CTR=0

for (( ; ; ))
do
	sleep 15
	BUILD_STATUS=$(aws codebuild batch-get-builds --ids $BUILD_ID | jq -r '.builds[0].buildStatus')
	if [[ "$BUILD_STATUS" = "SUCCEEDED"  ]]
	then
		break
	fi
	if [[ "$CTR" -gt "20" ]]
	then
		exit 1
	fi
	CTR=$(($CTR+1))
	echo $CTR
done

```

For the CloudFormation and Python SDK implementations, similar build trigger constructs are achieved with a [`go` script](s3_thumbnail_creator/cloudformation/cb/cb.go) and a [`python` script](https://github.com/Faaizz/cloud_learnings/blob/b97336b48436c20d9944125d5d2e34976343cef8/s3_thumbnail_creator/python_sdk/core/codebuild_actions.py#L64-L84) respectively. They trigger the project build and wait (for a maximum of 5 minutes) for the build to succeed.


### Thumbnail Generation Lambda

*TL;DR*
- *CloudFormation requires S3 Bucket Notifications to be configured when declaring a bucket. This can result in cyclic dependencies when notification destinations also need information about the bucket in their declaration.*
- *Python SDK requires that a lambda function be active before permissions can be configured. This can usually be implemented using a waiter.*

Now that the container image for the Thumbnail Generation lambda has been built and pushed to ECR, the lambda function that uses it can be defined.
The process of creating the lambda function in all 3 implementations is pretty straightforward.
The only caveat is, while specifying the trust permission to allow the Source S3 bucket invoke the lambda function, the Source buckets ARN has to be manually constructed (as `aws:arn:s3:::<source_bucket_name>`) to avoid cyclic dependencies. This is because the lambda function's ARN is required to configure bucket notifications on the Source bucket, and in CloudFormation, bucket notifications must be specified at bucket declaration time.

With Terraform, the `aws_lambda_function` and `aws_lambda_permission` resource blocks create the lambda function and updates its resource policy to allow invocation from the Source bucket. An execution role is setup with the `aws_iam_role` resource block, with a policy attached to grant CloudWatch logs permissions, and allow the lambda function to save the created thumbnails to the Destination bucket.

In the Python SDK implementation, after making the API call to create the lambda function, a waiter is configured to pause the execution until the newly created function is active. This helps to prevent errors when trying to grant invocation permissions to the Source bucket (since permissions can only be added when the function becomes active).
```python
lambda_client.boto3.client('lambda')
waiter = lambda_client.get_waiter('function_active')
waiter.wait(
  FunctionName=lambda_function_name,
  WaiterConfig={
      'Delay': 5,
      'MaxAttempts': 60,
  }
)
```


### S3 Bucket Name Macro

*TL;DR*
- *CloudFormation does not have mechanisms to generate random numbers out of the box.*
- *CloudFormation macros must be created before they can be used.*

Python and terraform provide mechanisms to generate pseudo-random numbers (e.g., `rand.randint()` and the `random` provider's `random_integer` respectively). These are used to generate pseudo-random bucket names for the Source and Destination S3 buckets. CloudFormation does not have such mechanisms out of the box.
To complement this, a lambda function-backed CloudFormation macro is utilized to generate S3 bucket names for the CloudFormation implementation as shown below.
```yaml
...
Resources:
  RandomBucketNameLambda:
    Type: AWS::Lambda::Function
    Properties:
      Role: !GetAtt
          - RandomBucketNameLambdaRole
          - Arn
      Runtime: python3.9
      Description: Lambda function that generates random S3 bucket names
      Code:
        ZipFile: |
          import random
          def handler(event, context):
            name_prefix = event['params']['Prefix']
            random_bucket_name = '{}-{}'.format(name_prefix, random.randint(5000, 9000))
            return {
              'requestId': event['requestId'],
              'status': 'success',
              'fragment': random_bucket_name,
            }
      Handler: index.handler
  RandomBucketNameMacro:
    Type: AWS::CloudFormation::Macro
    Properties:
      Name: !Ref MacroName
      Description: Generate random bucket name
      # Gotcha ARN here, not function name
      FunctionName: !GetAtt
        - RandomBucketNameLambda
        - Arn
...
```
The function logic is provided to the CloudFormation template in-line, hence, no external source is configured.

It is worthy to note that CloudFormation macros must exist before they can be used. I.e., a stack must be created from the template that declares a macro before the macro can be used in other templates. You CANNOT declare and use a macro in the same template.


## Cleanup

*TL;DR*
- *Terraform is the best of the 3 in terms of cleanup.*

Terraform handles cleanup seamlessly due to it's state-tracking mechanism.
For resources that can have child resources---e.g., S3 buckets and ECR repositories---specifying a `force_destroy` attribute in the terraform resource block is enough to enable terraform automatically delete all child resources at cleanup time to allow deletion of the parent resource. With terraform, resource cleanup is as simple as running `terraform destroy --auto-approve`.

For CloudFormation, deployed resources can be deleted by deleting the stack in which they're contained. However, there is no magic-trick to enforce deletion of parent resources with existing child resources.

Cleaning up resources deployed in the Python SDK implementation required some extra efforts.
The identifiers of deployed resources are tracked in a JSON file, which is then loaded into the cleanup script.
For parent resources with existing child resources, the child resources are traversed and deleted.


## Roundup
Terraform was the most convenient to use in my opinion.
The declarative syntax was straightforward and the cleanup was very easy.
Also, the execution time averaged 152 seconds across 3 runs.
In terms of comfort and ease-of-use, terraform was the best.

The Python SDK implementation gave more insight into the underlying constructs of the AWS API.
It executed slightly faster than terraform, with an average execution time of 146 seconds across 3 runs. 
From a learning perspective, the Python SDK rocks :-).

I can't really make much of a a case for using CloudFormation except for its compactness (if written in YAML, I think JSON is quite verbose :-/).
Like terraform, it uses a declarative syntax. But, I found terraform much more convenient (might be because I hadn't really used CloudFormation before now).
The CloudFormation implementation executed a lot slower than the other two methods, yielding an average execution time of 438 seconds across 3 runs.

In summary, the terraform implementation was the most usable, while the Python SDK provided the most learnings.


## References

### Terraform
- [https://registry.terraform.io/providers/hashicorp/aws/latest/docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### CloudFormation
- [https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-reference.html](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-reference.html)
- [https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-product-attribute-reference.html](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-product-attribute-reference.html)
- [https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html)

### CodeBuild
- [https://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html](https://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html)
- [https://docs.aws.amazon.com/codebuild/latest/userguide/getting-started-cli-create-build-project.html](https://docs.aws.amazon.com/codebuild/latest/userguide/getting-started-cli-create-build-project.html)

### AWS SDK
- [https://docs.aws.amazon.com/sdk-for-go/](https://docs.aws.amazon.com/sdk-for-go/)
