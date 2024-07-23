output "s3_access_grants_application_arn" {
  value = aws_ssoadmin_application.s3_access_grants_application.application_arn
}

output "s3_access_grants_trusted_token_issuer_arn" {
  value = aws_ssoadmin_trusted_token_issuer.jumpcloud_trusted_issuer.arn
}
