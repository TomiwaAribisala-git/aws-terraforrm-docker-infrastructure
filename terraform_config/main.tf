data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "public_subnet1" {
  vpc_id = data.aws_vpc.default.id
  id = var.subnet1_id
}

data "aws_subnet" "public_subnet2" {
  vpc_id = data.aws_vpc.default.id
  id = var.subnet2_id
}

data "aws_ami" "latest-amazon-ami-image" {
    most_recent      = true
    owners           = ["amazon"]
    filter {
        name   = "name"
        values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_subnet" "private_subnet1" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = var.private-subnet1-cidr-block
  availability_zone       = var.avail_zone1
  tags = {
    Name = "private_subnet1"
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = var.private-subnet2-cidr-block
  availability_zone       = var.avail_zone2
  tags = {
    Name = "private_subnet2"
  }
}

resource "aws_nat_gateway" "nat_gateway1" {
  allocation_id = aws_eip.node-instance-eip1.id
  subnet_id    = data.aws_subnet.public_subnet1.id
}

resource "aws_eip" "node-instance-eip1" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway2" {
  allocation_id = aws_eip.node-instance-eip2.id
  subnet_id    = data.aws_subnet.public_subnet2.id
}

resource "aws_eip" "node-instance-eip2" {
  domain = "vpc"
}


resource "aws_route_table" "private_subnet1_route_table" {
  vpc_id = data.aws_vpc.default.id
  route {
    cidr_block = var.private-subnet1-route-table-cidr-block
    nat_gateway_id = aws_nat_gateway.nat_gateway1.id
  }
}

resource "aws_route_table" "private_subnet2_route_table" {
  vpc_id = data.aws_vpc.default.id
  route {
    cidr_block = var.private-subnet2-route-table-cidr-block
    nat_gateway_id = aws_nat_gateway.nat_gateway2.id
  }
}

resource "aws_route_table_association" "private_subnet1_route_table_association" {
    subnet_id = aws_subnet.private_subnet1.id 
    route_table_id = aws_route_table.private_subnet1_route_table.id 
}

resource "aws_route_table_association" "private_subnet2_route_table_association" {
    subnet_id = aws_subnet.private_subnet2.id 
    route_table_id = aws_route_table.private_subnet2_route_table.id 
}

resource "aws_security_group" "alb-sg" { 
    name        = "alb-sg"
    vpc_id      = data.aws_vpc.default.id

    ingress {
        description      = "alb default HTTP port"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"] 
    }

    tags = {
        Name = "alb-sg"
    }
}

# Security group for VPC Endpoints
resource "aws_security_group" "vpc_endpoint_security_group" {
  name_prefix = "vpc-endpoint-sg"
  vpc_id      = data.aws_vpc.default.id
  description = "security group for VPC Endpoints"

  # Allow inbound HTTPS traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
    description = "Allow HTTPS traffic from VPC"
  }

  tags = {
    Name = "VPC Endpoint security group"
  }
}

resource "aws_security_group" "server-sg" { 
    name        = "server-sg"
    vpc_id      = data.aws_vpc.default.id

    ingress {
        description      = "load balancer access"
        from_port        = 5555
        to_port          = 5555
        protocol         = "tcp"
        security_groups = [aws_security_group.alb-sg.id]
    }

    ingress {
        description      = "load balancer access"
        from_port        = 8080
        to_port          = 8080
        protocol         = "tcp"
        security_groups = [aws_security_group.alb-sg.id]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"] 
    }

    tags = {
        Name = "server-sg"
    }
}

locals {
  endpoints = {
    "endpoint-ssm" = {
      name = "ssm"
    },
    "endpoint-ssmm-essages" = {
      name = "ssmmessages"
    },
    "endpoint-ec2-messages" = {
      name = "ec2messages"
    }
  }
}

resource "aws_vpc_endpoint" "endpoints" {
  vpc_id            = data.aws_vpc.default.id
  for_each          = local.endpoints
  service_name      = "com.amazonaws.${var.region}.${each.value.name}"
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.vpc_endpoint_security_group.id]
}

# Create IAM role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "EC2_SSM_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AmazonSSMManagedInstanceCore policy to the IAM role
resource "aws_iam_role_policy_attachment" "ec2_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_role.name
}

# Create an instance profile for the EC2 instance and associate the IAM role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2_SSM_Instance_Profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_lb" "node-alb" {
  name               = var.alb-name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [data.aws_subnet.public_subnet1.id, data.aws_subnet.public_subnet2.id]
  enable_deletion_protection = false
  tags = {
    name = "node-alb"
  }
}

resource "aws_lb_target_group" "nginx-lb-tg" {
  name        = var.nginx-tg-name
  port        = var.nginx-tg-port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_lb_target_group" "node-lb-tg" {
  name        = var.node-tg-name
  port        = var.node-tg-port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_lb_target_group_attachment" "nginx-target-group-attachment1" {
  target_group_arn = aws_lb_target_group.nginx-lb-tg.arn
  target_id        = aws_instance.node-instance1.private_ip
  port             = var.nginx-tg-attachment1-port
}

resource "aws_lb_target_group_attachment" "node-target-group-attachment1" {
  target_group_arn = aws_lb_target_group.node-lb-tg.arn
  target_id        = aws_instance.node-instance1.private_ip
  port             = var.node-tg-attachment1-port
}

resource "aws_lb_target_group_attachment" "nginx-target-group-attachment2" {
  target_group_arn = aws_lb_target_group.nginx-lb-tg.arn
  target_id        = aws_instance.node-instance2.private_ip
  port             = var.nginx-tg-attachment2-port
}

resource "aws_lb_target_group_attachment" "node-target-group-attachment2" {
  target_group_arn = aws_lb_target_group.node-lb-tg.arn
  target_id        = aws_instance.node-instance2.private_ip
  port             = var.node-tg-attachment2-port
}

resource "aws_lb_listener" "nginx-listener" {
  load_balancer_arn = aws_lb.node-alb.arn
  port              = var.nginx-listener-port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx-lb-tg.arn
  }
}

resource "aws_lb_listener" "node-listener" {
  load_balancer_arn = aws_lb.node-alb.arn
  port              = var.node-listener-port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.node-lb-tg.arn
  }
}

resource "aws_instance" "node-instance1" {
    ami                     = data.aws_ami.latest-amazon-ami-image.id 
    instance_type           = var.instance_type
    subnet_id               = aws_subnet.private_subnet1.id 
    vpc_security_group_ids  = [aws_security_group.server-sg.id]
    iam_instance_profile    = aws_iam_instance_profile.ec2_instance_profile.name
    tags = {
        Name = "node-instance1"
    }
}

resource "aws_instance" "node-instance2" {
    ami                     = data.aws_ami.latest-amazon-ami-image.id 
    instance_type           = var.instance_type
    subnet_id               = aws_subnet.private_subnet2.id 
    vpc_security_group_ids  = [aws_security_group.server-sg.id]
    iam_instance_profile    = aws_iam_instance_profile.ec2_instance_profile.name
    tags = {
        Name = "node-instance2"
    }
}