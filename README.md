# AWS S3 Access Grants

| Department         | Accessible S3 Resources                  | Access Type |
|--------------------|------------------------------------------|-------------|
| Marketing          | s3://shopfast-data/products/             | Read        |
|                    | s3://shopfast-data/feedback/             | Read        |
| Sales              | s3://shopfast-data/transactions/         | Read/Write  |
|                    | s3://shopfast-data/users/                | Read/Write  |
| Customer Support   | s3://shopfast-data/users/                | Read        |
|                    | s3://shopfast-data/feedback/             | Read/Write  |
| Product Management | s3://shopfast-data/products/             | Read/Write  |
|                    | s3://shopfast-internal/leads/            | Read        |
| HR                 | s3://shopfast-internal/employee-records/ | Read/Write  |
|                    | s3://shopfast-internal/benefits/         | Read/Write  |

![Access Pattern Plan](./mermaid-diagram.png)

## Deploy Terraform

Run the following commands to deploy the terraform stack

```bash
terraform init
terraform apply
```

## Request Access Credentials

### Example of failed request

```bash
export AWS_DEFAULT_REGION=ap-southeast-2
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_ROLE_TO_ASSUME=arn:aws:iam::$AWS_ACCOUNT_ID:role/ShopFast-CustomerSupport
export SHOPFAST_DATA_BUCKET=$(terraform output -raw shopfast_data_bucket)

# Sets the AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_SESSION_TOKEN environment variables
CREDENTIALS_JSON=$(aws sts assume-role --role-arn $AWS_ROLE_TO_ASSUME --role-session-name ShopFastRole)
export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS_JSON | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS_JSON | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS_JSON | jq -r '.Credentials.SessionToken')

aws s3control get-data-access \
    --account-id $AWS_ACCOUNT_ID \
    --target s3://$SHOPFAST_DATA_BUCKET/users* \
    --permission READWRITE \
    --privilege Default

# An error occurred (AccessDenied) when calling the GetDataAccess operation: You do not have READWRITE permissions to the requested S3 Prefix: s3://terraform-20231210044558274900000002/users*
```

### Example of successful request

```bash
export AWS_DEFAULT_REGION=ap-southeast-2
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_ROLE_TO_ASSUME=arn:aws:iam::$AWS_ACCOUNT_ID:role/ShopFast-CustomerSupport
export SHOPFAST_DATA_BUCKET=$(terraform output -raw shopfast_data_bucket)

# Sets the AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_SESSION_TOKEN environment variables
CREDENTIALS_JSON=$(aws sts assume-role --role-arn $AWS_ROLE_TO_ASSUME --role-session-name ShopFastRole)
export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS_JSON | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS_JSON | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS_JSON | jq -r '.Credentials.SessionToken')

CREDENTIALS_JSON=$(aws s3control get-data-access \
    --account-id $AWS_ACCOUNT_ID \
    --target s3://$SHOPFAST_DATA_BUCKET/users* \
    --permission READ \
    --privilege Default)
# {
#     "Credentials": {
#         "AccessKeyId": "ASIAZZZZZZZZZZZZZZZZ",
#         "SecretAccessKey": "RA+YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY",
#         "SessionToken": "IQoJb3JpZ2luXXXXXXXXXXXXXXXXXXXXXXXXXX",
#         "Expiration": "2023-12-06T16:16:19+00:00"
#     },
#     "MatchedGrantTarget": "s3://terraform-20231210044558274900000002/users*"
# }

export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS_JSON | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS_JSON | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS_JSON | jq -r '.Credentials.SessionToken')

$ aws sts get-caller-identity
# {
#     "UserId": "ASIAZZZZZZZZZZZZZZZZ:access-grants-ade86c3c-4781-4c65-8beb-4639bb72f5e6",
#     "Account": "012345678912",
#     "Arn": "arn:aws:sts::012345678912:assumed-role/terraform-20231210044558274900000002/access-grants-ade86c3c-4781-4c65-8beb-4639bb72f5e6"
# }
```

Get object

```bash
aws s3api get-object --bucket terraform-20231210044558274900000002 --key users/user_list user_list_downloaded
# {
#     "AcceptRanges": "bytes",
#     "LastModified": "2023-12-10T05:00:37+00:00",
#     "ContentLength": 32,
#     "ETag": "\"4aa99f977fb1e5ba4d846e408f6a90ba\"",
#     "ContentType": "application/octet-stream",
#     "ServerSideEncryption": "AES256",
#     "Metadata": {}
# }
```
