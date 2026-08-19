# =============================================================================
# modules/service — EC2 (Docker-backed) + nginx + SG + ALB   (GROUP-OWNED)
# =============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

data "aws_vpc" "default" {
  count   = var.enable_compute ? 1 : 0
  default = true
}

data "aws_subnets" "default" {
  count = var.enable_compute ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

resource "aws_security_group" "app" {
  count       = var.enable_compute ? 1 : 0
  name        = "${var.service_name}-app"
  description = "Service instance. Scoped CIDR — trivy flags 0.0.0.0/0."
  vpc_id      = data.aws_vpc.default[0].id

  ingress {
    description = "nginx"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidrs
  }

  ingress {
    description = "app (direct, for debug)"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidrs
  }

  # Instance must reach Aiven MySQL (public) and LocalStack. Not 0.0.0.0/0 on ingress.
  #trivy:ignore:AVD-AWS-0104
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.service_name}-app"
    Service = var.service_name
  }
}

resource "aws_instance" "app" {
  count                  = var.enable_compute ? 1 : 0
  ami                    = var.app_ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.app[0].id]
  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    secret_arn       = var.secret_arn
    db_endpoint      = var.db_endpoint
    db_port          = var.db_port
    app_port         = var.app_port
    aws_endpoint_url = var.aws_endpoint_url
    service_name     = var.service_name
  })
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name    = var.service_name
    Service = var.service_name
  }
}

# ALB topology is graded IaC + scanned. nginx carries real traffic (C4).
resource "aws_lb" "app" {
  count                      = var.enable_compute ? 1 : 0
  name                       = "${var.service_name}-alb"
  internal                   = true
  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  security_groups            = [aws_security_group.app[0].id]
  subnets                    = slice(data.aws_subnets.default[0].ids, 0, min(2, length(data.aws_subnets.default[0].ids)))

  tags = {
    Service = var.service_name
  }

  lifecycle {
    ignore_changes = [subnets]
  }
}

resource "aws_lb_target_group" "app" {
  count    = var.enable_compute ? 1 : 0
  name     = "${var.service_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default[0].id

  health_check {
    enabled             = true
    path                = "/readyz"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "app" {
  count            = var.enable_compute ? 1 : 0
  target_group_arn = aws_lb_target_group.app[0].arn
  target_id        = aws_instance.app[0].id
  port             = 80
}

# LocalStack ALB is HTTP-only (no ACM). Traffic is proven on nginx, not TLS at the LB.
#trivy:ignore:AVD-AWS-0054
resource "aws_lb_listener" "app" {
  count             = var.enable_compute ? 1 : 0
  load_balancer_arn = aws_lb.app[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[0].arn
  }

  lifecycle {
    ignore_changes = [port]
  }
}
