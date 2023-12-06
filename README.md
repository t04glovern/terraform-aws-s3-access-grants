# AWS S3 Access Grants

## Deploy Terraform

Update backend.tf with your terraform backend configuration

```bash
terraform init
terraform apply
```

## Request Access Credentials

### Example of failed request

```bash
export AWS_DEFAULT_REGION=ap-southeast-2
export AWS_ACCESS_KEY_ID=ASIAXXXXXXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=yK+YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY

aws s3control get-data-access \
    --account-id $(aws sts get-caller-identity --query Account --output text) \
    --target s3://terraform-20231206143658553600000001/prefixA* \
    --permission READ \
    --privilege Default

# An error occurred (AccessDenied) when calling the GetDataAccess operation: You do not have READ permissions to the requested S3 Prefix: s3://terraform-20231206143658553600000001/prefixA*
```

### Example of successful request

```bash
export AWS_DEFAULT_REGION=ap-southeast-2
export AWS_ACCESS_KEY_ID=ASIAXXXXXXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=yK+YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY

aws s3control get-data-access \
    --account-id $(aws sts get-caller-identity --query Account --output text) \
    --target s3://terraform-20231206143658553600000001/prefixB* \
    --permission READ \
    --privilege Default > credentials.json

# {
#     "Credentials": {
#         "AccessKeyId": "ASIAZZZZZZZZZZZZZZZZ",
#         "SecretAccessKey": "RA+YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY",
#         "SessionToken": "IQoJb3JpZ2luXXXXXXXXXXXXXXXXXXXXXXXXXX",
#         "Expiration": "2023-12-06T16:16:19+00:00"
#     },
#     "MatchedGrantTarget": "s3://terraform-20231206143658553600000001/prefixB*"
# }
```

Set `aws configure set`

```bash
aws configure set aws_access_key_id $(jq -r '.Credentials.AccessKeyId' credentials.json)
aws configure set aws_secret_access_key $(jq -r '.Credentials.SecretAccessKey' credentials.json)
aws configure set aws_session_token $(jq -r '.Credentials.SessionToken' credentials.json)

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
```

Get object

```bash
aws s3api get-object --bucket terraform-20231206143658553600000001 --key prefixB/hello_world hello_world_downloaded
# {
#     "AcceptRanges": "bytes",
#     "LastModified": "2023-12-06T15:19:33+00:00",
#     "ContentLength": 34,
#     "ETag": "\"e445b33d9d14618ac31aeb65ccbfd265\"",
#     "ContentType": "application/octet-stream",
#     "ServerSideEncryption": "AES256",
#     "Metadata": {}
# }
```
