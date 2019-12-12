provider "aws" {
    region = "eu-central-1"
}

# Copy 1-to-1 from S3 global configuration
# only bucket key is changed to reflect folder structure
terraform {
  backend "s3" {
    bucket  = "terraform-up-and-running-state-bruno"
    key     = "stage/data-stores/mysql/terraform.tfstate"
    region  = "eu-central-1"

    # DynamoDB table for locking
    # This resource is declared down there
    dynamodb_table  = "terraform-up-and-running-locks"
    encrypt         = true
  }
}


resource "aws_db_instance" "example" {
  identifier_prefix = "terraform-up-and-running"
  engine            = "mysql"
  allocated_storage = 10
  instance_class    = "db.t2.micro"
  name              = "example_database"
  username          = "admin"
  # How can we set the password without writing it down here?
  password          = var.db_password
}