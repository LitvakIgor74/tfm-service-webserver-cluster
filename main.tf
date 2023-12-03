terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "5.25.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}


# ------------------------------------------------------------------ locals
locals {
  http_port = 80
  any_port = 0
  http_protocol = "HTTP"
  tcp_protocol = "tcp"
  any_protocol = "-1"
  all_ips = ["0.0.0.0/0"]
}


# ------------------------------------------------------------------ data sources
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


# ------------------------------------------------------------------ ELB: load balancer
resource "aws_lb" "alb" {
  name = "${var.unique_prefix}-${var.project_name}-alb"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port = local.http_port
  protocol = local.http_protocol
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code = "404"
      message_body = "404: resource not found."
    }
  }
}

resource "aws_lb_listener_rule" "all_pathes" {
  listener_arn = aws_lb_listener.alb_listener.arn
  priority = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.all_http.arn
  }
}

resource "aws_lb_target_group" "all_http" {
  name = "${var.unique_prefix}-${var.project_name}-all-http-tg"
  vpc_id = data.aws_vpc.default.id
  port = var.instance_server_port
  protocol = local.http_protocol
  health_check {
    path = "/"
    protocol = local.http_protocol
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_security_group" "alb_sg" {
  name = "${var.unique_prefix}-${var.project_name}-alb-sg"
}

resource "aws_security_group_rule" "http_port_tcp_ingress" {
  security_group_id = aws_security_group.alb_sg.id
  type = "ingress"
  from_port = local.http_port
  to_port = local.http_port
  protocol = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "any_port_any_egress" {
  security_group_id = aws_security_group.alb_sg.id
  type = "egress"
  from_port = local.any_port
  to_port = local.any_port
  protocol = local.any_protocol
  cidr_blocks = local.all_ips
}


# ------------------------------------------------------------------ EC2 Autoscaling Group
resource "aws_autoscaling_group" "all_http_traffic" {
  vpc_zone_identifier = data.aws_subnets.default.ids
  min_size = var.asg_min_size
  max_size = var.asg_max_size
  launch_configuration = aws_launch_configuration.instance.name
  target_group_arns = [aws_lb_target_group.all_http.arn]
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "${var.unique_prefix}-${var.project_name}-asg"
    propagate_at_launch = true
  }
  dynamic "tag" {
    for_each = var.custom_tags
    content {
      key = tag.key
      value = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_launch_configuration" "instance" {
  instance_type = var.instance_type
  image_id = "ami-0fb653ca2d3203ac1"
  security_groups = [aws_security_group.instance_sg.id]
  user_data = templatefile(
    "${path.root}/app.sh",
    {db_address = var.db_address, db_port = var.db_port, instance_server_port = var.instance_server_port}
  )
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance_sg" {
  name = "${var.unique_prefix}-${var.project_name}-sg"
}

resource "aws_security_group_rule" "instance_server_port_tcp_ingress" {
  security_group_id = aws_security_group.instance_sg.id
  type = "ingress"
  from_port = var.instance_server_port
  to_port = var.instance_server_port
  protocol = local.tcp_protocol
  cidr_blocks = local.all_ips
}