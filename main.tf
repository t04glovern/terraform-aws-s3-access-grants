data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "example" {}

resource "aws_iam_user" "example" {
  name  = "example"
}

data "aws_iam_policy_document" "example_policy" {
  statement {
    actions = [
      "s3:ListAccessGrants",
      "s3:ListAccessGrantsLocations",
      "s3:GetDataAccess"
    ]

    resources = [
      "arn:aws:s3:ap-southeast-2:${data.aws_caller_identity.current.account_id}:access-grants/default",
    ]
  }
}

resource "aws_iam_user_policy" "example" {
  name   = "example"
  user   = aws_iam_user.example.name
  policy = data.aws_iam_policy_document.example_policy.json
}

resource "aws_s3_object" "prefixA" {
  bucket = aws_s3_bucket.example.bucket
  key    = "prefixA/"
}

resource "aws_s3_object" "prefixB" {
  bucket = aws_s3_bucket.example.bucket
  key    = "prefixB/"
}

resource "aws_s3_object" "prefixB_hello_world" {
  bucket = aws_s3_bucket.example.bucket
  key    = "prefixB/hello_world"
  source = "hello_world"
}

resource "aws_s3control_access_grants_instance" "example" {
  identity_center_arn = "arn:aws:sso:::instance/ssoins-xxxxxxxxxxxxxx"
}

resource "aws_iam_role" "example" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Stmt1234567891011"
        Action    = ["sts:AssumeRole", "sts:SetSourceIdentity"]
        Effect    = "Allow"
        Principal = { Service = "access-grants.s3.amazonaws.com" }
      }
    ]
  })

  inline_policy {
    name = "example"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "ObjectLevelReadPermissions"
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetObjectAcl",
            "s3:GetObjectVersionAcl",
            "s3:ListMultipartUploadParts",
          ]
          Resource = ["arn:aws:s3:::*"]
          Condition = {
            StringEquals = { "aws:ResourceAccount" = data.aws_caller_identity.current.account_id }
            ArnEquals = {
              "s3:AccessGrantsInstanceArn" = ["arn:aws:s3:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:access-grants/default"]
            }
          }
        },
        {
          Sid    = "ObjectLevelWritePermissions"
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:PutObjectAcl",
            "s3:PutObjectVersionAcl",
            "s3:DeleteObject",
            "s3:DeleteObjectVersion",
            "s3:AbortMultipartUpload",
          ]
          Resource = ["arn:aws:s3:::*"]
          Condition = {
            StringEquals = { "aws:ResourceAccount" = data.aws_caller_identity.current.account_id }
            ArnEquals = {
              "s3:AccessGrantsInstanceArn" = ["arn:aws:s3:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:access-grants/default"]
            }
          }
        },
        {
          Sid    = "BucketLevelReadPermissions"
          Effect = "Allow"
          Action = ["s3:ListBucket"]
          Resource = ["arn:aws:s3:::*"]
          Condition = {
            StringEquals = { "aws:ResourceAccount" = data.aws_caller_identity.current.account_id }
            ArnEquals = {
              "s3:AccessGrantsInstanceArn" = ["arn:aws:s3:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:access-grants/default"]
            }
          }
        }
      ]
    })
  }
}

resource "aws_s3control_access_grants_location" "example" {
  depends_on = [aws_s3control_access_grants_instance.example]

  iam_role_arn   = aws_iam_role.example.arn
  location_scope = "s3://${aws_s3_bucket.example.bucket}"
}

resource "aws_s3control_access_grant" "example" {
  access_grants_location_id = aws_s3control_access_grants_location.example.access_grants_location_id
  permission                = "READ"

  access_grants_location_configuration {
    s3_sub_prefix = "prefixB*"
  }

  grantee {
    grantee_type       = "IAM"
    grantee_identifier = aws_iam_user.example.arn
  }
}
