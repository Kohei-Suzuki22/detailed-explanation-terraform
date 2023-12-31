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

  tags = {
    Name = "terraform_vpc_subnet"
  }
}



resource "aws_instance" "example" {
  
  subnet_id = aws_subnet.terraform_vpc_subnet.id
  ami = "ami-07c589821f2b353aa"
  instance_type = "t2.micro"

  tags = {
    Name = "terraform_example"
  }
  
}