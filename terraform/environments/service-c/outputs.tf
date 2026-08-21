output "instance_id" {
  value = module.service.instance_id
}

output "secret_arn" {
  value = module.data.secret_arn
}

output "db_endpoint" {
  value = module.data.db_endpoint
}

output "db_port" {
  value = module.data.db_port
}

output "db_name" {
  value = module.data.db_name
}

output "db_username" {
  value = module.data.db_username
}

output "patient_count" {
  value = module.data.patient_count
}

output "alb_dns_name" {
  value = module.service.alb_dns_name
}
