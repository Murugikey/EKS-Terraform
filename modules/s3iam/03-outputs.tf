output "iam_instance_profile_name" {
    description = "Commom instance profile"
    value       = aws_iam_instance_profile.commom_instance_profile.name
}
output "iam_instance_profile_arn" {
    description = "Commom instance profile"
    value       = aws_iam_instance_profile.commom_instance_profile.arn
}
output "access_logs_bucket_id" {
    value= aws_s3_bucket.access_logs_bucket.id
}

output "access_logs_bucket_name" {
    value= aws_s3_bucket.access_logs_bucket.bucket
}