terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }

  backend "s3" {
    bucket                     = "rh-tfstate-service-c"
    key                        = "service-c/terraform.tfstate"
    region                     = "us-east-1"
    dynamodb_table             = "rh-tflock"
    encrypt                    = true
    skip_requesting_account_id = true
    use_path_style             = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "regional-health"
      Service     = "service-c"
      Environment = "localstack"
      ManagedBy   = "terraform"
    }
  }
}
