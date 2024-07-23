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
#     "Account": "111111111111",
#     "Arn": "arn:aws:sts::111111111111:assumed-role/terraform-20231210044558274900000002/access-grants-ade86c3c-4781-4c65-8beb-4639bb72f5e6"
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

## Deploy Terraform (SSO)

> Note: To perform these steps, there must be an existing AWS IAM Identity Center (IIC) instance and a user (or group) in the directory. I won't be covering how to setup AWS IAM Identity Center (IIC) in this guide.

Create a new file `terraform.tfvars` with the following content

```hcl
sso_instance_id  = "ssoins-XXXXXXXXXXXXX"
sso_grantee = {
  "type": "DIRECTORY_USER",
  "id": "97670ae0f2-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX"
}
```

Deploying these changes will link AWS S3 Access Grants to IAM Identity Center (IIC)

```bash
# Set AWS credentials for the S3 Access Grant account (111111111111 in the example)
export AWS_ACCESS_KEY_ID=XXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
export AWS_SESSION_TOKEN=ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ

terraform init
terraform apply
```

Export some variables while you are still authenticated with the S3 Access grant account (used for terraform deploy)

```bash
export SHOPFAST_DATA_BUCKET=$(terraform output -raw shopfast_data_bucket)
export AWS_S3_ACCESS_GRANT_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_S3_ACCESS_GRANT_ROLE_ARN=$(terraform output -raw identity_bearer_iam_role_arn)
export AWS_S3_ACCESS_GRANT_CLIENT_APP_ROLE_ARN=$(terraform output -raw client_application_iam_role_arn)
```

***!!!*** The following steps must be done while authenticated with the AWS IAM Identity Center (IIC) account. ***!!!***

```bash
# Set AWS credentials for the AWS IAM Identity Center (IIC) account (222222222222 in the example)
export AWS_ACCESS_KEY_ID=XXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
export AWS_SESSION_TOKEN=ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ

cd federation
terraform init
terraform apply
```

There are a few steps that do not have terraform resources, so they must be done manually - Start by exporting some variables

```bash
export AWS_IIC_APPLICATION_ARN=$(terraform output -raw s3_access_grants_application_arn)
export AWS_IIC_TRUSTED_ISSUER_ARN=$(terraform output -raw s3_access_grants_trusted_token_issuer_arn)
```

Create an application grant for the application

```bash
export AWS_IIC_APPLICATION_AUTHORIZED_AUDIENCE="8943e428-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

GRANT_JSON=$(jq --arg issuer_arn "$AWS_IIC_TRUSTED_ISSUER_ARN" \
    --arg audience "$AWS_IIC_APPLICATION_AUTHORIZED_AUDIENCE" \
        '.JwtBearer.AuthorizedTokenIssuers[0].TrustedTokenIssuerArn = $issuer_arn |
        .JwtBearer.AuthorizedTokenIssuers[0].AuthorizedAudiences[0] = $audience' \
        templates/grant.json)

aws sso-admin put-application-grant \
    --application-arn $AWS_IIC_APPLICATION_ARN \
    --grant-type "urn:ietf:params:oauth:grant-type:jwt-bearer" \
    --grant "$GRANT_JSON"
```

Create an application authentication method for the application

```bash
AUTHENTICATION_METHOD_JSON=$(jq \
    --arg app_arn "$AWS_IIC_APPLICATION_ARN" \
    --arg role_arn "$AWS_S3_ACCESS_GRANT_CLIENT_APP_ROLE_ARN" \
    --arg aws_id "$AWS_S3_ACCESS_GRANT_ACCOUNT_ID" \
        '.Iam.ActorPolicy.Statement[0].Principal.AWS = $aws_id |
        .Iam.ActorPolicy.Statement[0].Resource = $app_arn |
        .Iam.ActorPolicy.Statement[0].Condition.ArnEquals["aws:PrincipalArn"] = $role_arn' \
        templates/authentication-method.json)

aws sso-admin put-application-authentication-method \
   --application-arn $AWS_IIC_APPLICATION_ARN \
   --authentication-method-type IAM \
   --authentication-method "$AUTHENTICATION_METHOD_JSON"
```

Generate the `.env` file in the `federation/web` folder that will be used by the client application

```bash
cat <<EOF > web/.env
FLASK_SECRET_KEY=Your_Secret_Key
AWS_IIC_APPLICATION_ARN=${AWS_IIC_APPLICATION_ARN}
AWS_S3_ACCESS_GRANT_ROLE_ARN=${AWS_S3_ACCESS_GRANT_ROLE_ARN}
AWS_S3_ACCESS_GRANT_ACCOUNT_ID=${AWS_S3_ACCESS_GRANT_ACCOUNT_ID}
AWS_TARGET_BUCKET_NAME=${SHOPFAST_DATA_BUCKET}
EOF
```

## Run the client application

Setup the client application dependencies

```bash
cd federation/web

# Install dependencies
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Create a copy of `client_secrets.json.example` and rename it to `client_secrets.json`. Update the `client_id` and `client_secret` with values from your IDP (in our case, JumpCloud).

```bash
cp client_secrets.json.example client_secrets.json
```

Setup credentials then run the client application

```bash
# Set AWS credentials for the S3 Access Grant account (111111111111 in the example)
export AWS_ACCESS_KEY_ID=XXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
export AWS_SESSION_TOKEN=ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ

# Assume the S3 Access Grant role
CREDENTIALS_JSON=$(aws sts assume-role --role-arn $AWS_S3_ACCESS_GRANT_CLIENT_APP_ROLE_ARN --role-session-name s3-access-grants)
export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS_JSON | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS_JSON | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS_JSON | jq -r '.Credentials.SessionToken')

# Run the client application
python3 jumpcloud.py
```

Login at [http://localhost:5000/login](http://localhost:5000/login), then navigate to [http://localhost:5000/get-s3-data](http://localhost:5000/get-s3-data) to view the data.

## Cleanup

Remove AWS IAM Identity Center configuration

```bash
# Set AWS credentials for the AWS IAM Identity Center (IIC) account (222222222222 in the example)
export AWS_ACCESS_KEY_ID=XXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
export AWS_SESSION_TOKEN=ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ

cd federation
terraform init
terraform destroy
```

Remove AWS S3 Access Grants configuration

```bash
# Set AWS credentials for the S3 Access Grant account (111111111111 in the example)
export AWS_ACCESS_KEY_ID=XXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
export AWS_SESSION_TOKEN=ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ

cd ..
terraform init
terraform destroy
```
