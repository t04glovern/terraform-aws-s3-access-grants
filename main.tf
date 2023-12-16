data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "shopfast_data" {}

resource "aws_s3_bucket" "shopfast_internal" {}

resource "aws_s3_object" "shopfast_data_products" {
  bucket = aws_s3_bucket.shopfast_data.bucket
  key    = "products/"
}

resource "aws_s3_object" "shopfast_data_feedback" {
  bucket = aws_s3_bucket.shopfast_data.bucket
  key    = "feedback/"
}

resource "aws_s3_object" "shopfast_data_transactions" {
  bucket = aws_s3_bucket.shopfast_data.bucket
  key    = "transactions/"
}

resource "aws_s3_object" "shopfast_data_users" {
  bucket = aws_s3_bucket.shopfast_data.bucket
  key    = "users/"
}

resource "aws_s3_object" "shopfast_data_users_list" {
  bucket = aws_s3_bucket.shopfast_data.bucket
  key    = "users/user_list"
  source = "user_list"
}

resource "aws_s3_object" "shopfast_internal_leads" {
  bucket = aws_s3_bucket.shopfast_internal.bucket
  key    = "leads/"
}

resource "aws_s3_object" "shopfast_internal_employee_records" {
  bucket = aws_s3_bucket.shopfast_internal.bucket
  key    = "employee-records/"
}

resource "aws_s3_object" "shopfast_internal_benefits" {
  bucket = aws_s3_bucket.shopfast_internal.bucket
  key    = "benefits/"
}

locals {
  departments = ["Marketing", "Sales", "CustomerSupport", "ProductManagement", "HumanResources"]
}

data "aws_iam_policy_document" "department_policy" {
  statement {
    actions = [
      "s3:ListAccessGrants",
      "s3:ListAccessGrantsLocations",
      "s3:GetDataAccess"
    ]

    resources = [
      "arn:aws:s3:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:access-grants/default",
    ]
  }
}

resource "aws_iam_policy" "department_policy" {
  name   = "ShopFast-Access-Grant-Policy"
  policy = data.aws_iam_policy_document.department_policy.json
}

resource "aws_iam_role" "department_roles" {
  for_each = toset(local.departments)

  name = "ShopFast-${each.value}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = ["sts:AssumeRole"]
        Effect    = "Allow"
        Principal = { "AWS" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "department_policy_attachment" {
  for_each = toset(local.departments)

  role       = aws_iam_role.department_roles[each.value].name
  policy_arn = aws_iam_policy.department_policy.arn
}

resource "aws_s3control_access_grants_instance" "shopfast_instance" {
  identity_center_arn = var.sso_instance_id != "" ? "arn:aws:sso:::instance/${var.sso_instance_id}" : null
}

resource "aws_iam_role" "shopfast_location_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Stmt1234567891011"
        Action    = ["sts:AssumeRole", "sts:SetSourceIdentity", "sts:SetContext"]
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
          Sid      = "BucketLevelReadPermissions"
          Effect   = "Allow"
          Action   = ["s3:ListBucket"]
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

resource "aws_s3control_access_grants_location" "shopfast_data_location" {
  depends_on = [aws_s3control_access_grants_instance.shopfast_instance]

  iam_role_arn   = aws_iam_role.shopfast_location_role.arn
  location_scope = "s3://${aws_s3_bucket.shopfast_data.bucket}"
}

resource "aws_s3control_access_grants_location" "shopfast_internal_location" {
  depends_on = [aws_s3control_access_grants_instance.shopfast_instance]

  iam_role_arn   = aws_iam_role.shopfast_location_role.arn
  location_scope = "s3://${aws_s3_bucket.shopfast_internal.bucket}"
}

resource "aws_s3control_access_grant" "department_grants" {
  for_each = {
    "Marketing-products"              = { location = aws_s3control_access_grants_location.shopfast_data_location.access_grants_location_id, prefix = "products*", permission = "READ" }
    "Marketing-feedback"              = { location = aws_s3control_access_grants_location.shopfast_data_location.access_grants_location_id, prefix = "feedback*", permission = "READ" }
    "Sales-transactions"              = { location = aws_s3control_access_grants_location.shopfast_data_location.access_grants_location_id, prefix = "transactions*", permission = "READWRITE" }
    "Sales-users"                     = { location = aws_s3control_access_grants_location.shopfast_data_location.access_grants_location_id, prefix = "users*", permission = "READWRITE" }
    "CustomerSupport-users"           = { location = aws_s3control_access_grants_location.shopfast_data_location.access_grants_location_id, prefix = "users*", permission = "READ" }
    "CustomerSupport-feedback"        = { location = aws_s3control_access_grants_location.shopfast_data_location.access_grants_location_id, prefix = "feedback*", permission = "READWRITE" }
    "ProductManagement-products"      = { location = aws_s3control_access_grants_location.shopfast_data_location.access_grants_location_id, prefix = "products*", permission = "READWRITE" }
    "ProductManagement-leads"         = { location = aws_s3control_access_grants_location.shopfast_internal_location.access_grants_location_id, prefix = "leads*", permission = "READ" }
    "HumanResources-employee-records" = { location = aws_s3control_access_grants_location.shopfast_internal_location.access_grants_location_id, prefix = "employee-records*", permission = "READWRITE" }
    "HumanResources-benefits"         = { location = aws_s3control_access_grants_location.shopfast_internal_location.access_grants_location_id, prefix = "benefits*", permission = "READWRITE" }
  }

  access_grants_location_id = each.value.location
  permission                = each.value.permission

  access_grants_location_configuration {
    s3_sub_prefix = each.value.prefix
  }

  grantee {
    grantee_type       = var.sso_grantee.type
    grantee_identifier = var.sso_grantee.type != "IAM" ? var.sso_grantee.id : null
  }
}
