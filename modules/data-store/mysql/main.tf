terraform {
  backend "s3" {
    bucket         = var.db_remote_state_bucket
    key            = var.db_remote_state_key
    region         = var.db_remote_state_bucket_region
    dynamodb_table = var.db_remote_state_dynamodb_table_name
    encrypt        = true
  }
}

resource "aws_db_instance" "example" {
  identifier_prefix = "terraform-up-and-running"
  engine            = "mysql"
  allocated_storage = 10
  instance_class    = "db.t2.micro"
  name              = var.db_name
  username          = var.db_user
  # How can we set the password without writing it down here?
  # Using environment variables like TF_VAR_[variable_here]
  # should be automatically available as var.variable_here
  password          = var.db_password
  skip_final_snapshot = true
}