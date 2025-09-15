# Useful to keep track of some value
output "state_bucket_name" {
  description = "S3 bucket name used for remote state"
  value = aws_s3_bucket.tf_state.bucket
}

output "state_bucket_arn" {
  description = "S3 bucket ARN"
  value = aws_s3_bucket.tf_state.arn
}

output "dynamodb_lock_table" {
  description = "DynamoDB table for state locking"
  value = aws_dynamodb_table.tf_lock.name
}