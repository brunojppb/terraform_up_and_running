provider "aws" {
    region = "eu-central-1"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"
}