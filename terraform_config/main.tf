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

resource "aws_subnet" "private_subnet" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = var.private-subnet-cidr-block
  availability_zone       = var.avail_zone
  tags = {
    Name = "private_subnet"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.node-instance-eip.id
  subnet_id    = data.aws_subnet.public_subnet1.id
}

resource "aws_eip" "node-instance-eip" {
  domain = "vpc"
}

resource "aws_route_table" "private_subnet_route_table" {
  vpc_id = data.aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "private_subnet_route_table_association" {
    subnet_id = aws_subnet.private_subnet.id 
    route_table_id = aws_route_table.private_subnet_route_table.id 
}

resource "aws_security_group" "alb-sg" { 
    name        = "alb-sg"
    vpc_id      = data.aws_vpc.default.id

    ingress {
        description      = "user access"
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

resource "aws_security_group" "server-sg" { 
    name        = "server-sg"
    vpc_id      = data.aws_vpc.default.id

    ingress {
        description      = "ssh"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
        description      = "load balancer access"
        from_port        = 5555
        to_port          = 5555
        protocol         = "tcp"
        security_groups = [aws_security_group.alb-sg.id]
    }

    ingress {
        description      = "load balancer access"
        from_port        = 80
        to_port          = 80
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

resource "aws_lb_target_group" "node-target-group" {
  name     = "node-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_lb_target_group_attachment" "node-target-group-attachment" {
  target_group_arn = aws_lb_target_group.node-target-group.arn
  target_id        = aws_instance.node-instance.id
  port             = 80
}

resource "aws_lb_listener" "node-listener" {
  load_balancer_arn = aws_lb.node-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.node-target-group.arn
  }
}

resource "aws_instance" "node-instance" {
    ami                     = data.aws_ami.latest-amazon-ami-image.id 
    instance_type           = var.instance_type
    subnet_id               = aws_subnet.private_subnet.id 
    vpc_security_group_ids  = [aws_security_group.server-sg.id]
    associate_public_ip_address = true
    key_name = var.private-key
    tags = {
        Name = "node-instance"
    }
}

resource "null_resource" "configure_server" {
    triggers = {
        trigger = aws_instance.node-instance.public_ip
    }
    provisioner "local-exec" {
        working_dir = "/mnt/c/Users/Tomiwa/sample-node-mongo-api/ansible_config"
        command = "ansible-playbook --inventory ${aws_instance.node-instance.public_ip} --private-key ${var.ssh_private_key} --user ec2-user node-mongo-playbook.yml"
    }
}