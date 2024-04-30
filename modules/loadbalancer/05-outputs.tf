output "aws_lb_listeners_arns" {
  description = "List of Listners ARNs"
  value       = aws_lb_listener.listeners[*].arn
}

output "aws_lb_arn" {
  description = "Load balancer ARN"
  value       = aws_lb.loadbalancer.arn
}


output "default_lb_sg" {
  description = "Load Balancer security group id"
  value       = var.TYPE == "application" ? aws_security_group.default_lb_sg[*].id : null
}