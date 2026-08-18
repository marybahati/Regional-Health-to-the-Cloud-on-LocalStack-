variable "service_name" {
  type        = string
  description = "Owning service (service-a / service-b / service-c)."
}

variable "app_ami_id" {
  type        = string
  description = "AMI id in the form ami-<12 hex chars>, matching localstack-ec2/<name>:ami-<12 hex>."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type. t3.small leaves headroom for nginx + Node."
  default     = "t3.small"
}

variable "secret_arn" {
  type        = string
  description = "Secrets Manager ARN. User-data receives this, never the value."
}

variable "db_endpoint" {
  type        = string
  description = "MySQL host passed to user-data for reachability (not the password)."
}

variable "db_port" {
  type        = number
  description = "MySQL port."
  default     = 3306
}

variable "app_port" {
  type        = number
  description = "Node listen port behind nginx."
  default     = 3000
}

variable "aws_endpoint_url" {
  type        = string
  description = "AWS_ENDPOINT_URL for the SDK. Unset this on real AWS."
  default     = "http://localhost.localstack.cloud:4566"
}

variable "ingress_cidrs" {
  type        = list(string)
  description = "SG ingress. Not 0.0.0.0/0 — trivy config fails that."
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "enable_compute" {
  type        = bool
  description = "Create Docker-backed EC2 + ELBv2. Requires LocalStack Pro. Community mode uses scripts/run-app-local.sh instead."
  default     = true
}
