*Note: It is assumed that all instructions provided below are bing run from a terminal opened in the same directory that this file resides.*

## Steps to run

1. [Install `aws` CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
2. [Install `terraform`](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
3. [Install `jq`](https://stedolan.github.io/jq/download/) (used in the [build script](./scripts/build.sh))
4. Provide AWS credentials
```sh
cat <<EOF > terraform.tfvars
aws_access_key_id     = "AKIAYXZCRWKDO7VXXXXX"
aws_secret_access_key = "HB7uCOA/xywHXfHSbCyVmKg7R7t3Z/xxxxxxxxxx"
EOF
```
5. Start the deployment
    ```sh
    terraform deploy --auto-approve
    ```

## Steps to cleanup
After successfully deploying the application, a cleanup can be performed with:
```sh
terraform destroy --auto-approve
```
