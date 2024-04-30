output "instance_address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.rds_instance.address
}

output "instance_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.rds_instance.endpoint
}