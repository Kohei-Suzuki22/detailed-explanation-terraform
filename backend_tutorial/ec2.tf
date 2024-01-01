
resource "aws_vpc" "vpc_sample" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "terraform_vpc"
  }
}

resource "aws_subnet" "vpc_sample_subnet_1a" {
  vpc_id = aws_vpc.vpc_sample.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "terraform_vpc_subnet"
  }
  
}



resource "aws_instance" "example" {
  subnet_id = aws_subnet.vpc_sample_subnet_1a.id
  ami = "ami-07c589821f2b353aa"
  instance_type = "t2.micro"
  
}