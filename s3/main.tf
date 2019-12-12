# Current terraform limitation:
# - We have to create the remote backend (S3 Bucket) and the DynamoDB from our local machine first
# - only then we associate the bucket with the terraform backend and sync the state from our local machine

provider "aws" {
  region = "eu-central-1"
}

# Step 1:
# This resource must be created on the first Terraform apply
# only then we can declare the terraform backend to use it.
# This is one of the terraform gotchas ¯\_(ツ)_/¯
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-up-and-running-state-bruno"

  # prevent accidental deletion of this bucket
  lifecycle {
    prevent_destroy = true
  }

  # Enable versioning so we can see the full revision history of our state files
  versioning {
    enabled = true
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

}

# Now we need a locking mechanism, so we make sure that 2 concurrent deploys don't overlap each other
# for that we will use DynamoDB, which is a kind of Redis (key-value store) to prevent multiple writes
# into our bucket, potentially causing a corrupt state
resource "aws_dynamodb_table" "terraform_locks" {
  name          = "terraform-up-and-running-locks"
  billing_mode  = "PAY_PER_REQUEST"
  hash_key      = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Step 2:
# Now lets use this S3 Bucket as our terraform state backend
terraform {
  backend "s3" {
    bucket  = "terraform-up-and-running-state-bruno"
    key     = "global/s3/terraform.tfstate"
    region  = "eu-central-1"

    # DynamoDB table for locking
    # This resource is declared down there
    dynamodb_table  = "terraform-up-and-running-locks"
    encrypt         = true
  }
}