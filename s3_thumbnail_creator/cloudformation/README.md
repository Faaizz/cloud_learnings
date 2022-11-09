*Note: It is assumed that all instructions provided below are bing run from a terminal opened in the same directory that this file resides.*

## Steps to run

1. [Install `aws` CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
2. [Install `go`](https://go.dev/doc/install)
3. [Provide AWS credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html). E.g.,
    ```bash
    export AWS_ACCESS_KEY_ID="AKIARFOCEPH3M6VXXXXX"
    export AWS_SECRET_ACCESS_KEY="eZkz325XVlFwHIrg9Yo0vvK8Aowbxfxxxxxxxxxx"
    export AWS_DEFAULT_REGION="us-east-1"
    ```
4. Start the deployment
    ```sh
    go run .
    ```
