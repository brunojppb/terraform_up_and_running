provider "aws" {
    region = "eu-central-1"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"
  
  cluster_name = "webservers-prod"
  db_remote_state_bucket = "terraform-up-and-running-state-bruno"
  db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"
}