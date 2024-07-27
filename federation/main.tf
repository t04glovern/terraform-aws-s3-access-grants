data "aws_ssoadmin_instances" "current" {}

resource "aws_ssoadmin_trusted_token_issuer" "jumpcloud_trusted_issuer" {
  name                      = "S3AccessGrantsIssuer"
  instance_arn              = tolist(data.aws_ssoadmin_instances.current.arns)[0]
  trusted_token_issuer_type = "OIDC_JWT"

  trusted_token_issuer_configuration {
    oidc_jwt_configuration {
      claim_attribute_path          = "email"
      identity_store_attribute_path = "emails.value"
      issuer_url                    = var.issuer_url
      jwks_retrieval_option         = "OPEN_ID_DISCOVERY"
    }
  }
}

resource "aws_ssoadmin_application" "s3_access_grants_application" {
  name                     = "S3AccessGrants"
  application_provider_arn = "arn:aws:sso::aws:applicationProvider/custom"
  instance_arn             = tolist(data.aws_ssoadmin_instances.current.arns)[0]
}

resource "aws_ssoadmin_application_assignment_configuration" "s3_access_grants_application_assignment_configuration" {
  application_arn     = aws_ssoadmin_application.s3_access_grants_application.application_arn
  assignment_required = false
}

resource "aws_ssoadmin_application_access_scope" "s3_access_grants_application_access_scope" {
  application_arn    = aws_ssoadmin_application.s3_access_grants_application.application_arn
  scope              = "s3:access_grants:read_write"
}

