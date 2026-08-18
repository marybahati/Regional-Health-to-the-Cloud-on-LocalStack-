output "instance_id" {
  description = "EC2 instance id for the app."
  value       = aws_instance.app.id
}

output "nginx_url" {
  description = "Host-reachable nginx URL (port 80 on instance public IP)."
  value       = "http://${aws_instance.app.public_ip}"
}

output "app_url" {
  description = "Direct app URL for debugging."
  value       = "http://${aws_instance.app.public_ip}:${var.app_port}"
}

output "alb_dns_name" {
  description = "ALB DNS name (declared for IaC; nginx carries traffic in lab)."
  value       = aws_lb.app.dns_name
}
