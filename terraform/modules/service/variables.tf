variable "service_name" {
  type        = string
  description = "Logical service name (e.g. service-b)."
}

variable "app_ami_id" {
  type        = string
  description = "LocalStack EC2 AMI tag, e.g. localstack-ec2/service-b:ami-abc123def456."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type declared in IaC."
  default     = "t3.small"
}

variable "secret_arn" {
  type        = string
  description = "Secrets Manager ARN passed to user-data. Never the secret value."
}

variable "db_endpoint" {
  type        = string
  description = "MySQL host endpoint (Aiven)."
}

variable "db_port" {
  type        = number
  description = "MySQL port."
  default     = 3306
}

variable "app_port" {
  type        = number
  description = "Application listen port."
  default     = 3002
}

variable "aws_endpoint_url" {
  type        = string
  description = "LocalStack endpoint for the app SDK."
  default     = "http://host.docker.internal:4566"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}
