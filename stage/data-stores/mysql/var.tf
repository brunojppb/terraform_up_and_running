# There are a few ways to inject this variable
# 1 - use Amazon secret keys manager (aws_secretmanager_secret_version) to read directly in the code
# 2 - use environment variables like TF_VAR_[REST_OF_VARIABLE_HERE] e.g. export TF_VAR_db_password

# WARNING: even passing ENV variables to Terraform, the secrets will be stored in plain text inside terraform state
# so be aware that it will be stored in the S3 bucket. make sure it is encrypted at rest

variable "db_password" {
  description = "database password"
  type = string
}