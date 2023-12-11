output "shopfast_data_bucket" {
  value = aws_s3_bucket.shopfast_data.bucket
}

output "shopfast_internal_bucket" {
  value = aws_s3_bucket.shopfast_internal.bucket
}
