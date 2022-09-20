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
    region = "us-east-1"
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
    map_public_ip_on_launch = true
    availability_zone = "us-east-1a"


    
    tags = {
    Name = "public_subnet_1a"
}
}

resource "aws_subnet" "public_subnet_1b" {
    vpc_id = aws_vpc.aws_prod_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true

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


#create route table to internet gateway
resource "aws_route_table" "tf_route" {
    vpc_id = aws_vpc.aws_prod_vpc.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.aws_ig.id
    }
    tags = {
    Name = "terraform"
}

}

#Associate public subnets with route table
resource "aws_route_table_association" "public_route_1" {
    subnet_id = aws_subnet.public_subnet_1a.id
    route_table_id = aws_route_table.tf_route.id
}

resource "aws_route_table_association" "public_route_2" {
    subnet_id = aws_subnet.public_subnet_1b.id
    route_table_id = aws_route_table.tf_route.id
  
}

#create security groups

resource "aws_security_group" "public_sg" {
    name = "public-sg"
    description = "Allow web and ssh traffic"
    vpc_id = aws_vpc.aws_prod_vpc.id

 
    ingress {
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }
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


resource "aws_security_group" "private_sg" {
    name = "private-sg"
    description = "Allow web and ssh traffic"
    vpc_id = aws_vpc.aws_prod_vpc.id

    ingress {
      description = "private traffic"
      from_port = 80
      protocol = "tcp"
      to_port = 80
      cidr_blocks = ["0.0.0.0/0"]
    } 

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/16"]
        security_groups = [ aws_security_group.public_sg.id ]
    }

    egress {
        from_port = 0
        to_port =0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

resource "aws_security_group" "alb_sg" {
    name = "alb-sg"
    description = "security group for alb"
    vpc_id = aws_vpc.aws_prod_vpc.id

    ingress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

#Create ALB

resource "aws_lb" "tf_alb" {
    name = "alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [ aws_security_group.alb_sg.id ]
    subnets = [ aws_subnet.public_subnet_1a.id , aws_subnet.public_subnet_1b.id ]  
}

#create ALB Target group
resource "aws_lb_target_group" "alb_tg" {
  name = "alb-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.aws_prod_vpc.id
  depends_on = [
    aws_vpc.aws_prod_vpc
  ]
}

resource "aws_lb_target_group_attachment" "alb_tg_1" {
    target_group_arn = aws_lb_target_group.alb_tg.arn
    target_id = aws_instance.web1.id
    port = 80
    depends_on = [
      aws_instance.web1
    ]

}

resource "aws_lb_target_group_attachment" "alb_tg_2" {
    target_group_arn = aws_lb_target_group.alb_tg.arn
    target_id = aws_instance.web2.id
    port = "80"

}

resource "aws_lb_listener" "listener_lb" {
    load_balancer_arn = aws_lb.tf_alb.arn
    port = "80"
    protocol = "HTTP"

    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.alb_tg.arn
    }

}


#create ec2 instance
resource "aws_instance" "web1" {
    ami = "ami-0fd218145ecba0193"
    instance_type = "t2.micro"
    key_name = "awsvirgin"
    availability_zone = "us-east-1b"
    vpc_security_group_ids = [ aws_security_group.public_sg.id]
    subnet_id = aws_subnet.public_subnet_1b.id
    user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start httpd
        systemctl enable httpd
        echo "<html><body><h1>Hi there</h1></body></html>" > /var/www/html/index.html
        EOF

        tags = {
            Name = "Web_1_instance"
        }
}


resource "aws_instance" "web2" {
    ami ="ami-0fd218145ecba0193"  
    instance_type = "t2.micro"
    key_name = "awsvirgin"
    availability_zone = "us-east-1d"
    vpc_security_group_ids = [ aws_security_group.private_sg.id ]
    subnet_id = aws_subnet.private_subnet1b.id
    user_data = <<-EOF
        #!/bin/bash
        yum install httpd -y
         systemctl start httpd
        systemctl enable httpd
        echo "<html><body><h1>Hi there</h1></body></html>" > /var/www/html/index.html
        EOF

        tags = {
          "Name" = "Web_2_instance"
        }

}