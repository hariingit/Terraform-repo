terraform{
    required_providers {
        aws = {
            source ="hashicorp/aws"
            version = "~>4.2"
        }
    }
}

#configure provider
provider "aws"{
    profile = "awsprod"
    region = "ap-south-1"
}

#Create VPC

resource "aws_vpc" "aws_prod_vpc" {

cidr_block = "10.0.0.0/16"
instance_tenancy = "default"

tags = {
    Name = "terraform"
}
}

resource "aws_internet_gateway" "aws_ig" {
  vpc_id = aws_vpc.aws_prod_vpc.id

  tags = {
    Name = "terraform"
}
}

resource "aws_subnet" "public_subnet_1a" {
    vpc_id = aws_vpc.aws_prod_vpc.id
    cidr_block = "10.0.1.0/24"
    
    tags = {
    Name = "public_subnet_1a"
}
}

resource "aws_subnet" "public_subnet_1b" {
    vpc_id = aws_vpc.aws_prod_vpc.id
    cidr_block = "10.0.2.0/24"

    tags = {
    Name = "public_subnet_1b"
}
}

resource "aws_subnet" "private_subnet1a" {
    vpc_id = aws_vpc.aws_prod_vpc.id
    cidr_block = "10.0.3.0/24"

    tags = {
    Name = "private_subnet1a"
}
}
resource "aws_subnet" "private_subnet1b" {
    vpc_id = aws_vpc.aws_prod_vpc.id
    cidr_block = "10.0.4.0/24"

    tags = {
      "Name" = "private_subnet1b"
    }
}
