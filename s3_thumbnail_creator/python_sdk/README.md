*Note: It is assumed that all instructions provided below are bing run from a terminal opened in the same directory that this file resides.*

## Steps to run

1. [Install `aws` CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
2. [Install `python`](https://www.python.org/downloads/)
3. [Install `pip`](https://pip.pypa.io/en/stable/installation/)
4. Install required python dependencies
    ```sh
    python3 -m pip install -r requirements.txt
    ```
5. [Provide AWS credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html). E.g.,
    ```bash
    export AWS_ACCESS_KEY_ID="AKIARFOCEPH3M6VXXXXX"
    export AWS_SECRET_ACCESS_KEY="eZkz325XVlFwHIrg9Yo0vvK8Aowbxfxxxxxxxxxx"
    export AWS_DEFAULT_REGION="us-east-1"
    ```
6. Start the deployment
    ```sh
    python3 ./run.py
    ```

## Steps to cleanup
After successfully deploying the application, a cleanup can be performed with:
```sh
python3 ./cleanup.py
```
