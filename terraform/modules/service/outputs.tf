output "instance_id" {
  value       = var.enable_compute ? aws_instance.app[0].id : null
  description = "EC2 instance id (Docker-backed on LocalStack Pro). Null in community mode."
}

output "security_group_id" {
  value       = var.enable_compute ? aws_security_group.app[0].id : null
  description = "Application security group. Custom SGs are not enforced on LocalStack."
}

output "alb_dns_name" {
  value       = var.enable_compute ? aws_lb.app[0].dns_name : null
  description = "ALB DNS. Traffic still goes through nginx on the instance."
}

output "user_data" {
  value       = var.enable_compute ? aws_instance.app[0].user_data : null
  description = "Base64 user-data for evidence. Contains ARN + endpoint, never the password."
  sensitive   = true
}
