provider "aws" {
  region = "ap-northeast-1"
}


resource "aws_vpc" "terraform_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "terraform_vpc"
  }
}

resource "aws_subnet" "terraform_vpc_subnet" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "terraform_vpc_subnet"
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



resource "aws_instance" "example" {
  
  subnet_id = aws_subnet.terraform_vpc_subnet.id
  ami = "ami-07c589821f2b353aa"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  associate_public_ip_address = true

  user_data = <<-EOF
                  #!/bin/bash
                  echo "Hello, World" > index.html
                  nohup busybox httpd -f -p ${var.server_port} &
                 EOF

  user_data_replace_on_change = true

  tags = {
    Name = "terraform_example"
  }
  
}


variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080 
}


output "public_ip" {
  value = aws_instance.example.public_ip
  description = "The public IP address of the web server."
  
}