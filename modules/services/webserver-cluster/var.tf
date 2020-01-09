variable "server_port" {
    description = "The port the web server will be listening to HTTP calls"
    type        = number
    default     = 8080
}

variable "cluster_name" {
    description = "The name to use for all cluster resources"
    type = string
}

variable "db_remote_state_bucket" {
    description = "The name of the S3 bucket for the database's remote state"
    type = string
}

variable "db_remote_state_key" {
    description = "The path for the database's remote state in the S3 Bucket"
    type = string
}