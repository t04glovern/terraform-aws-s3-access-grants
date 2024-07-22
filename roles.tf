resource "aws_iam_role" "identity_bearer_iam_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.account_id
        }
        Action = [
          "sts:AssumeRole",
          "sts:SetContext"
        ]
        Condition = {
          ArnEquals = {
            "aws:PrincipalArn" = aws_iam_role.client_application_iam_role.arn
          }
          StringEquals = {
            "sts:RequestContext/identitycenter:InstanceArn" = "arn:aws:sso:::instance/${var.sso_instance_id}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "allow_s3_data_access" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetDataAccess"
        ]
        Resource = "arn:aws:s3:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:access-grants/default"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "identity_bearer_iam_policy_attachment" {
  role       = aws_iam_role.identity_bearer_iam_role.name
  policy_arn = aws_iam_policy.allow_s3_data_access.arn
}

resource "aws_iam_role" "client_application_iam_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.account_id # Replace this with Service principal when not testing locally.
        }
        Action = [
          "sts:AssumeRole"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "allow_create_token_with_iam" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sso-oauth:CreateTokenWithIAM"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:SetContext"
        ]
        Resource = aws_iam_role.identity_bearer_iam_role.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "client_application_iam_policy_attachment" {
  role       = aws_iam_role.client_application_iam_role.name
  policy_arn = aws_iam_policy.allow_create_token_with_iam.arn
}
