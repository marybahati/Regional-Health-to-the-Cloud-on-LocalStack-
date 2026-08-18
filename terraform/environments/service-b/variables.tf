variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "secret_name" {
  type    = string
  default = "service-b/db"
}

variable "db_name" {
  type    = string
  default = "capacity_lab"
}

variable "db_host" {
  type      = string
  sensitive = true
}

variable "db_port" {
  type    = number
  default = 3306
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "app_ami_id" {
  type        = string
  description = "localstack-ec2/service-b:ami-<12 hex chars>"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "app_port" {
  type    = number
  default = 3002
}

variable "aws_endpoint_url" {
  type    = string
  default = "http://host.docker.internal:4566"
}
