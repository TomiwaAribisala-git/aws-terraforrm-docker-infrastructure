data "aws_ami" "latest-amazon-ami-image" {
    most_recent      = true
    owners           = ["amazon"]
    filter {
        name   = "name"
        values = ["al2023-ami-2023.2.20231016.0-kernel-6.1-x86_64"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
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