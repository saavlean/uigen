output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "ec2_instance_ids" {
  description = "EC2 instance IDs"
  value       = aws_instance.web[*].id
}

output "ec2_public_ips" {
  description = "Public IPs of EC2 instances"
  value       = aws_instance.web[*].public_ip
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.main.arn
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = local.zone_id
}

output "route53_name_servers" {
  description = "Route 53 name servers (if zone was created)"
  value       = var.create_route53_zone ? aws_route53_zone.main[0].name_servers : []
}

output "application_url" {
  description = "Application URL"
  value       = "http://${var.subdomain}.${var.domain_name}"
}

output "alb_url" {
  description = "Load Balancer URL (use this if DNS is not configured yet)"
  value       = "http://${aws_lb.main.dns_name}"
}
