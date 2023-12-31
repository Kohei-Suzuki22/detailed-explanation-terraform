provider "aws" {
  region = "ap-northeast-1"
}


resource "aws_vpc" "terraform_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "terraform_vpc"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.terraform_vpc.id
  
}

resource "aws_subnet" "terraform_vpc_subnet" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "ap-northeast-1a"
  # map_public_ip_on_launch = true

  tags = {
    Name = "terraform_vpc_subnet"
  }
}


resource "aws_subnet" "terraform_vpc_subnet-d" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "172.16.11.0/24"
  availability_zone = "ap-northeast-1d"
  map_public_ip_on_launch = true

  tags = {
    Name = "terraform_vpc_subnet-d"
  }
}


resource "aws_security_group" "instance" {
  name = "terraform_example_instance"
  vpc_id = aws_vpc.terraform_vpc.id

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
}



# # resource "aws_instance" "example" {
  
# #   subnet_id = aws_subnet.terraform_vpc_subnet.id
# #   ami = "ami-07c589821f2b353aa"
# #   instance_type = "t2.micro"
# #   vpc_security_group_ids = [aws_security_group.instance.id]
# #   associate_public_ip_address = true

# #   user_data = <<-EOF
# #                   #!/bin/bash
# #                   echo "Hello, World" > index.html
# #                   nohup busybox httpd -f -p ${var.server_port} &
# #                  EOF

# #   user_data_replace_on_change = true

# #   tags = {
# #     Name = "terraform_example"
# #   }
  
# # }



resource "aws_launch_configuration" "example" {
  
  image_id = "ami-07c589821f2b353aa"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]



  associate_public_ip_address = true

  user_data = <<-EOF
                  #!/bin/bash
                  echo "Hello, World" > index.html
                  nohup busybox httpd -f -p ${var.server_port} &
                 EOF

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnets.terraform_vpc_subnet.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }

  
}



variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080 
}


# # output "public_ip" {
# #   value = aws_instance.example.public_ip
# #   description = "The public IP address of the web server."
  
# # }



data "aws_subnets" "terraform_vpc_subnet" {
  filter {
    name = "vpc-id"
    values = [aws_vpc.terraform_vpc.id]
  }
}

output "hello" {
  value = data.aws_subnets.terraform_vpc_subnet
  
}



resource "aws_lb" "example" {
  name = "terraform-asg-example"
  load_balancer_type = "application"
  # subnets = data.aws_subnets.terraform_vpc_subnet.ids
  subnets = [aws_subnet.terraform_vpc_subnet.id, aws_subnet.terraform_vpc_subnet-d.id]
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}


resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
  
}


resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  vpc_id = aws_vpc.terraform_vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
}


resource "aws_lb_target_group" "asg" {
  name = "terraform-asg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = aws_vpc.terraform_vpc.id


  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
  
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
  
}


