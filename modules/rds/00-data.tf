data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
# data "aws_secretsmanager_secret" "bo_data_sm_secret" {
#   arn = var.BO_DB_SECRET_ARN
# }
# data "aws_secretsmanager_secret_version" "bo_data_sm_secret_version" {
#   secret_id = data.aws_secretsmanager_secret.bo_data_sm_secret.id
# }