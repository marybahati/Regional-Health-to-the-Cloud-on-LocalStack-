module "data" {
  source        = "../../modules/data"
  service_name  = "service-a"
  db_host       = var.db_host
  db_port       = var.db_port
  db_username   = var.db_username
  db_password   = var.db_password
  db_name       = var.db_name
  db_ca_cert    = var.db_ca_cert
  secret_name   = "regional-health/service-a/db"
  patient_count = var.patient_count
}

module "service" {
  source           = "../../modules/service"
  service_name     = "service-a"
  app_ami_id       = var.app_ami_id
  instance_type    = "t3.small"
  secret_arn       = module.data.secret_arn
  db_endpoint      = module.data.db_endpoint
  db_port          = module.data.db_port
  app_port         = 3000
  aws_endpoint_url = "http://localhost.localstack.cloud:4566"
  enable_compute   = var.enable_compute
}
