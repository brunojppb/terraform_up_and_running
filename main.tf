provider "aws" {
    region = "eu-central-1"
}

# Input variables
variable "server_port" {
    description = "The port the web server will be listening to HTTP calls"
    type        = number
    default     = 8080
}

# Output variables 
output "public_ip" {
    description = "The public IP address of the web server"
    value       = aws_instance.example.public_ip
}


resource "aws_security_group" "instance" {
    name = "terraform-example-instance"
    ingress {
        from_port   = var.server_port
        to_port     = var.server_port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "example" {
    ami                     = "ami-09a83aee4e05196ae"
    instance_type           = "t2.micro"
    vpc_security_group_ids  = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "hello, world" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF

    tags = {
        Name = "terraform-example"
    }
}