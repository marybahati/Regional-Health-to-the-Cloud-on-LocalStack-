locals {
  localstack_endpoints = {
    ec2            = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    s3             = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    elbv2          = "http://localhost:4566"
  }
}

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = var.aws_region
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2            = local.localstack_endpoints.ec2
    secretsmanager = local.localstack_endpoints.secretsmanager
    s3             = local.localstack_endpoints.s3
    dynamodb       = local.localstack_endpoints.dynamodb
    elbv2          = local.localstack_endpoints.elbv2
  }

  default_tags {
    tags = {
      Project     = "rehosting-capacity-lab"
      Group       = "group-5"
      Environment = "rehost-lab"
      Service     = "service-b"
      ManagedBy   = "terraform"
      Owner       = "service-b-owner"
    }
  }
}

module "data" {
  source = "../../modules/data"

  secret_name = var.secret_name
  db_name     = var.db_name
  db_host     = var.db_host
  db_port     = var.db_port
  db_username = var.db_username
  db_password = var.db_password
}

module "service" {
  source = "../../modules/service"

  service_name     = "service-b"
  app_ami_id       = var.app_ami_id
  instance_type    = var.instance_type
  secret_arn       = module.data.secret_arn
  db_endpoint      = module.data.db_endpoint
  db_port          = module.data.db_port
  app_port         = var.app_port
  aws_endpoint_url = var.aws_endpoint_url
  aws_region       = var.aws_region
}
