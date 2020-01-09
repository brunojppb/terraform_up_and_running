provider "aws" {
    region = "eu-central-1"
}

# Data sources
# Read-only information from AWS and Terraform state files
data "aws_vpc" "default" {
    default = true
}

data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
}

# Read data directly from our S3 Bucket backend store
# This is read-only information from a previously created resource
# the output varibles from the DB module will be available under "db.outputs"
data "terraform_remote_state" "db" {
    backend = "s3"

    config = {
        bucket  = var.db_remote_state_bucket
        key     = var.db_remote_state_key
        region  = "eu-central-1"
    }

}

# Copy 1-to-1 from S3 global configuration
# only bucket key is changed to reflect folder structure
terraform {
  backend "s3" {
    bucket  = "terraform-up-and-running-state-bruno"
    key     = "stage/services/webserver-cluster/terraform.tfstate"
    region  = "eu-central-1"

    # DynamoDB table for locking
    # This resource is declared down there
    dynamodb_table  = "terraform-up-and-running-locks"
    encrypt         = true
  }
}


# Security group helps us to make available on the internet
# only the resources we need. that helps us to reduce the user surface and security risks
resource "aws_security_group" "instance" {
    name = "${var.cluster_name}security-group-instance"
    ingress {
        from_port   = var.server_port
        to_port     = var.server_port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Allow any IP Address range
    }
}

# Executable script rendered by Terraform
# to boot up our fake web app
data "template_file" "user_data" {
    template = file("user-data.sh")

    vars = {
        server_port = var.server_port
        db_address  = data.terraform_remote_state.db.outputs.address
        db_port     = data.terraform_remote_state.db.outputs.port 
    }
}

# Launch configuration setup for how the autoscaling group
# should be, like the EC2 instances to be used, which scripts to fire up during startup and so on
resource "aws_launch_configuration" "example" {
    image_id                = "ami-09a83aee4e05196ae"
    instance_type           = "t2.micro"
    security_groups         = [aws_security_group.instance.id]
    
    # 'rendered' property will make sure the script is rendered with variables applied
    user_data = data.template_file.user_data.rendered

    # this is necessary when using a launch configuration with an autoscaling group.
    # When changing a auto-scaling group, a whole new one must be created and the old one must be destroyed
    # It will make sure to create a new auto-scaling group before destroying the old one
    lifecycle {
        create_before_destroy = true
    }
}


# The autoscaling group is handling the EC2 instances acording to our needs
# it will pick up the launch configuration and will scale out or in based on our needs
resource "aws_autoscaling_group" "example" {

    launch_configuration = aws_launch_configuration.example.name
    vpc_zone_identifier  = data.aws_subnet_ids.default.ids

    # tells the autoscaling group to which instances it should redirect traffic.
    target_group_arns = [aws_lb_target_group.asg.arn]
    # It also uses the target group health checks instead of the VM (default EC2)
    health_check_type = "ELB"

    min_size = 2 # at least 2 EC2 instances will be running at any given time
    max_size = 10 # we can scale out up to 10 instances

    tag {
        key                 = "Name"
        value               = "terraform-asg-example"
        propagate_at_launch = true
    }
}

# Now lets put a load balancer in front of those EC2 instances provided by the autoscaling group
resource "aws_lb" "example" {
    name                = "${var.cluster_name}-asg"
    load_balancer_type  = "application"
    subnets             = data.aws_subnet_ids.default.ids
    security_groups     = [aws_security_group.alb.id]
}

# Now we have the load balancer, but this guy cannot handle anything outside of the VPC yet
# lets put a listener here on port 80. By default a Load Balancer cannot accept incoming traffic.
# we will need an extra security group for that
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
  protocol = "HTTP"
  # by default, return a shitty 404 page
  default_action {
      type = "fixed-response"

      fixed_response {
          content_type = "text/plain"
          message_body = "404: Page not found"
          status_code = 404
      }
  }
}

# This security group let our Load Balancer accept incoming traffic from the internet
resource "aws_security_group" "alb" {
    name = "${var.cluster_name}-alb"

    # Allow inbound HTTP requests
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow outbound requests
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1" # no idea about that
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# TODO: Whata hell is a target group?
resource "aws_lb_target_group" "asg" {
    name     = "${var.cluster_name}-asg"
    port     = var.server_port
    protocol = "HTTP"
    vpc_id   = data.aws_vpc.default.id

    health_check {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 15
        timeout             = 3
        healthy_threshold   = 2
        unhealthy_threshold = 2
    }

}

# now lets tie this all together with a listener rule that
# allows any path to reach our load balancer, which will distribute
# the load across the instances managed by the autoscaling group
resource "aws_lb_listener_rule" "asg" {
    # ARN: Amazon Resource Name
    listener_arn    = aws_lb_listener.http.arn
    priority        = 100
    
    # Allow any URL pattern
    condition {
        field = "path-pattern"
        values = ["*"]
    }

    # forward incoming calls to the load balancer target group
    action {
        type                = "forward"
        target_group_arn    = aws_lb_target_group.asg.arn 
    }

}