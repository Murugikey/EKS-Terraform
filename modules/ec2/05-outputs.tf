output "private_ip" {
  description = "Internal private IP"
  value       = aws_instance.ec2_instance[*].private_ip
}

output "instance_ids" {
  description = "Instance ID"
  value       = aws_instance.ec2_instance[*].id
}

#output "asg_private_ip" {
#  description = "Internal private IP"
#  value       = aws_autoscaling_group.asg[*].private_ip
#}

output "asg_instance_id" {
  description = "Instance ID"
  value       = aws_autoscaling_group.asg[*].id
}

output "asg_name" {
  description = "ASG Name ID"
  value       = aws_autoscaling_group.asg[*].name
}

output "security_group" {
  description = "EC2 security group"
  value       = aws_security_group.security_group.id
}