resource "aws_db_instance" "rds_instance" {
  identifier                = var.IDENTIFIER
  username                  = var.USERNAME
  password                  = var.PASSWORD
  engine                    = var.ENGINE
  engine_version            = local.engine_current_version
  storage_type              = var.STORAGE_TYPE
  allocated_storage         = var.ALLOCATED_STORAGE
  instance_class            = var.INSTANCE_CLASS
  license_model             = local.license_current_version
  multi_az                  = var.MULTI_AZ
  auto_minor_version_upgrade = false
  
  backup_window             = "01:00-02:00"
  backup_retention_period   = var.RETENTION_PERIOD
  copy_tags_to_snapshot     = true
  maintenance_window        = "mon:02:30-mon:05:00"
  skip_final_snapshot       = true
  storage_encrypted         = true
  vpc_security_group_ids    = [aws_security_group.rds_default_access_sg.id]
  port                      = var.PORT_ACCESS
  db_subnet_group_name      = aws_db_subnet_group.db_subnet_group.name
  kms_key_id                = aws_kms_key.postgres_db_key.arn
  parameter_group_name      = aws_db_parameter_group.general_db_parameter_group.name

  enabled_cloudwatch_logs_exports = local.logs_exports_current

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Name"         = "${var.NAME_PREFIX}"
      "Purpose"      = "RDS Instance ${upper(var.ENGINE)} DB for ${upper(var.DEFAULT_TAGS.Project)}"
      "SecurityZone" = "X2"
      "AutoTurnOFF"  = var.AUTO_TURN_OFF
      "StartTime"    = var.DB_START_TIME
      "StopTime"     = var.DB_STOP_TIME
      "${var.NAME_PREFIX}.Backup" = "true"
    }
  )

  lifecycle {
    ignore_changes = [
      # engine_version,
      backup_retention_period
    ]
  }
}

resource "aws_db_parameter_group" "general_db_parameter_group" {
  name_prefix = "${replace(var.NAME_PREFIX, "/[^-a-zA-Z0-9]/", "-")}-rds-pg" 
  family      = "${local.db_param_group_family}"
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Purpose"      = "${upper(var.DEFAULT_TAGS.Project)} ${upper(var.ENGINE)} Parameter Group DB"
    }
  )
  lifecycle {
    ignore_changes = [
      name_prefix,
      # tags, 
      # tags_all
    ]
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  subnet_ids = var.PVT_SUBNETS

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Name"         = "${var.NAME_PREFIX}-subnet.group-db"
      "Purpose"      = "${upper(var.DEFAULT_TAGS.Project)} ${upper(var.ENGINE)} DB Subnet Group "
      "SecurityZone" = "X2"
    }
  )
}
resource "aws_kms_key" "postgres_db_key" {
  enable_key_rotation      = "false"
  key_usage                = "ENCRYPT_DECRYPT"
  is_enabled               = true
  ##customer_master_key_spec = "RSA_4096"
  #policy = data.aws_iam_policy_document.kms_policy_document.json

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Name"         = "${var.NAME_PREFIX}.kms"
      "Purpose"      = "${upper(var.DEFAULT_TAGS.Project)} ${upper(var.ENGINE)} DB KMS Key"
      "SecurityZone" = "X2"
    }
  )
}