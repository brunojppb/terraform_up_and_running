# There are a few ways to inject this variable
# 1 - use Amazon secret keys manager (aws_secretmanager_secret_version) to read directly in the code
# 2 - use environment variables like TF_VAR_[REST_OF_VARIABLE_HERE] e.g. export TF_VAR_db_password

# WARNING: even passing ENV variables to Terraform, the secrets will be stored in plain text inside terraform state
# so be aware that it will be stored in the S3 bucket. make sure it is encrypted at rest

variable "db_password" {
  description = "database password"
  type = string
}

variable "db_name" {
  description = "database name"
  type = string
}

variable "db_user" {
  description = "database user"
  type = string
}

variable "db_remote_state_bucket" {
  description = "The bucket used for storing the terraform state"
  type = string  
}

variable "db_remote_state_key" {
  description = "The bucket key used to identify the state"
  type = string
}

variable "db_remote_state_bucket_region" {
  description = "The state bucket region"
  type = string
}

variable "db_remote_state_dynamodb_table_name" {
  description = "The dynamoDB table for locks"
  type = string
}