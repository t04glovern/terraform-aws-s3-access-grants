output "shopfast_data_bucket" {
  value = aws_s3_bucket.shopfast_data.bucket
}

output "shopfast_internal_bucket" {
  value = aws_s3_bucket.shopfast_internal.bucket
}

output "identity_bearer_iam_role_arn" {
  value = aws_iam_role.identity_bearer_iam_role.arn
}

output "client_application_iam_role_arn" {
  value = aws_iam_role.client_application_iam_role.arn
}
