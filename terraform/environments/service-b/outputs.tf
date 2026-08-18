output "secret_arn" {
  value = module.data.secret_arn
}

output "instance_id" {
  value = module.service.instance_id
}

output "nginx_url" {
  value = module.service.nginx_url
}

output "app_url" {
  value = module.service.app_url
}

output "alb_dns_name" {
  value = module.service.alb_dns_name
}
