# ALB Module - outputs.tf

output "lb_id" {
  description = "The ID and ARN of the load balancer we created"
  value       = aws_lb.this.id
}

output "lb_arn" {
  description = "The ID and ARN of the load balancer we created"
  value       = aws_lb.this.arn
}

output "lb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.this.dns_name
}

output "lb_arn_suffix" {
  description = "ARN suffix of our load balancer - can be used with CloudWatch"
  value       = aws_lb.this.arn_suffix
}

output "lb_zone_id" {
  description = "The zone_id of the load balancer to assist with creating DNS records"
  value       = aws_lb.this.zone_id
}

output "http_tcp_listener_arns" {
  description = "The ARN of the TCP and HTTP load balancer listeners created"
  value       = aws_lb_listener.this[*].arn
}

output "http_tcp_listener_ids" {
  description = "The IDs of the TCP and HTTP load balancer listeners created"
  value       = aws_lb_listener.this[*].id
}

output "target_group_arns" {
  description = "ARNs of the target groups. Useful for passing to your Auto Scaling group"
  value       = aws_lb_target_group.this[*].arn
}

output "target_group_arn_suffixes" {
  description = "ARN suffixes of our target groups - can be used with CloudWatch"
  value       = aws_lb_target_group.this[*].arn_suffix
}

output "target_group_names" {
  description = "Name of the target group. Useful for passing to your CodeDeploy Deployment Group"
  value       = aws_lb_target_group.this[*].name
}

output "target_group_attachments" {
  description = "ARNs of the target group attachment IDs"
  value       = aws_lb_target_group_attachment.this[*].id
}
