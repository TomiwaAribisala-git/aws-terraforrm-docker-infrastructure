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