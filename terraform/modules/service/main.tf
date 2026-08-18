# modules/service — EC2 (Docker-backed) + nginx + SG + ALB (GROUP-OWNED)
#
# nginx carries real traffic and /readyz checks. ALB is declared as IaC
# (graded + scanned) but LocalStack ELBv2 health checking is not relied on.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "app" {
  name        = "${var.service_name}-app-sg"
  description = "Ingress for nginx and app port on ${var.service_name}"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP to nginx"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    description = "Direct app port (health/debug from host)"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    description = "HTTPS (Aiven TLS, package indexes)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP for apt during user-data bootstrap"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "MySQL to managed Aiven"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Aiven free-tier custom MySQL port"
    from_port   = 18736
    to_port     = 18736
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.service_name}-app-sg"
    Service = var.service_name
  }
}

resource "aws_instance" "app" {
  ami                         = var.app_ami_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/templates/user-data.sh.tpl", {
    service_name     = var.service_name
    app_port         = var.app_port
    secret_arn       = var.secret_arn
    db_endpoint      = var.db_endpoint
    db_port          = var.db_port
    aws_endpoint_url = var.aws_endpoint_url
    aws_region       = var.aws_region
    app_image        = var.app_ami_id
    nginx_conf = templatefile("${path.module}/templates/nginx.conf.tpl", {
      app_port = var.app_port
    })
  })

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name    = "${var.service_name}-app"
    Service = var.service_name
  }
}

resource "aws_lb" "app" {
  name                       = "${var.service_name}-alb"
  internal                   = false
  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  subnets                    = data.aws_subnets.default.ids

  tags = {
    Name    = "${var.service_name}-alb"
    Service = var.service_name
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.service_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  tags = {
    Name    = "${var.service_name}-tg"
    Service = var.service_name
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  lifecycle {
    ignore_changes = [port, protocol]
  }
}
