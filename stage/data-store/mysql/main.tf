provider "aws" {
    region = "eu-central-1"
}

variable "db_password" {
  description = "Database password. Tip: Use an environment variable"
  type = string
}

module "mysql" {
  source = "../../../modules/data-store/mysql"
  
  db_name                             = "stage_db"
  db_user                             = "stage_db_user"
  db_password                         = var.db_password
  db_remote_state_bucket              = "terraform-up-and-running-state-bruno"
  db_remote_state_key                 = "stage/data-stores/mysql/terraform.tfstate"
  db_remote_state_bucket_region       = "eu-central-1"
  db_remote_state_dynamodb_table_name = "terraform-up-and-running-locks"
  
}