output "shopfast_data_bucket" {
  value = aws_s3_bucket.shopfast_data.bucket
}

output "shopfast_internal_bucket" {
  value = aws_s3_bucket.shopfast_internal.bucket
}

output "identity_bearer_iam_role_arn" {
  value = length(aws_iam_role.identity_bearer_iam_role) > 0 ? aws_iam_role.identity_bearer_iam_role[0].arn : ""
}

output "client_application_iam_role_arn" {
  value = length(aws_iam_role.client_application_iam_role) > 0 ? aws_iam_role.client_application_iam_role[0].arn : ""
}
