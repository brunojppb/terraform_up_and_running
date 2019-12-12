
output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "The ARN (Amazon Resource Name) of the S3 Bucket" 
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
  description = "Name of DynamoDB table used for terraform state locks"
}