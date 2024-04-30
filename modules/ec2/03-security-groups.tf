#################################
######## Security Groups ########
#################################

### EC2 Security Group ###
resource "aws_security_group" "security_group" {
  name        = "${var.NAME_PREFIX}-${var.TYPE}.${var.TAG_NAME}-sg"
  description = "${var.TAG_NAME} - ${var.INSTANCE_FUNCTION} Security Group - ${upper(var.DEFAULT_TAGS.Project)}"
  vpc_id      = var.VPC_ID

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Name"         = "${var.NAME_PREFIX}-${var.TAG_NAME}-${var.TYPE}.sg"
      "Purpose"      = "Security Group for ${var.TAG_NAME} ${var.TYPE} - ${upper(var.DEFAULT_TAGS.Project)} "
      "SecurityZone" = "X2"
    },
  )
}

# EC2 Security Group Traffic Rules

resource "aws_security_group_rule" "custom_sg_rule_for_sg" {
  count                    = length(var.AUTHORIZED_EC2_SG) 
  type                     = var.AUTHORIZED_EC2_SG[count.index].type
  source_security_group_id = var.AUTHORIZED_EC2_SG[count.index].security_group_id
  from_port                = var.AUTHORIZED_EC2_SG[count.index].from_port
  to_port                  = var.AUTHORIZED_EC2_SG[count.index].to_port
  description              = "Allow ${upper(var.AUTHORIZED_EC2_SG[count.index].type)} traffic to ${var.TYPE} from port ${var.AUTHORIZED_EC2_SG[count.index].to_port} to ${var.AUTHORIZED_EC2_SG[count.index].to_port} port for ${var.AUTHORIZED_EC2_SG[count.index].description}"
  protocol                 = var.AUTHORIZED_EC2_SG[count.index].protocol
  security_group_id        = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "custom_sg_rule_for_cidr" {
  count             = length(var.AUTHORIZED_EC2_CIDRS) 
  type              = var.AUTHORIZED_EC2_CIDRS[count.index].type
  cidr_blocks       = var.AUTHORIZED_EC2_CIDRS[count.index].cidr
  from_port         = var.AUTHORIZED_EC2_CIDRS[count.index].from_port
  to_port           = var.AUTHORIZED_EC2_CIDRS[count.index].to_port
  description       = "Allow ${upper(var.AUTHORIZED_EC2_CIDRS[count.index].type)} traffic to ${var.TYPE} from port ${var.AUTHORIZED_EC2_CIDRS[count.index].to_port} to ${var.AUTHORIZED_EC2_CIDRS[count.index].to_port} port for ${var.AUTHORIZED_EC2_CIDRS[count.index].description}"
  protocol          = var.AUTHORIZED_EC2_CIDRS[count.index].protocol
  security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "ssm_http_out_int" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.security_group.id
  cidr_blocks       = [var.VPC_CIDR]
  description       = "Security Group Rule to allow egress connections for ssm"
}

resource "aws_security_group_rule" "ec2_outbound_https" {
  count             = var.INSTANCE_FUNCTION == "BASTION" ? 1 : 0
  security_group_id = aws_security_group.security_group.id
  type              = "egress"
  description       = "Allow outgoing all HTTPS traffic (TCP/443) from EC2"
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  to_port           = 443
}

resource "aws_security_group_rule" "custom_ec2_rule_for_efs_ingress" {
  count                    = var.EFS_SECURITY_GROUP != null ? 1 : 0
  security_group_id        = var.EFS_SECURITY_GROUP.id
  source_security_group_id = aws_security_group.security_group.id
  type                     = "ingress"
  description              = "Allow EC2 Instance to mount EFS"
  protocol                 = "TCP"
  from_port                = 2049
  to_port                  = 2049
}

resource "aws_security_group_rule" "custom_ec2_rule_for_efs_egress" {
  count                    = var.EFS_SECURITY_GROUP != null ? 1 : 0
  security_group_id        = var.EFS_SECURITY_GROUP.id
  source_security_group_id = aws_security_group.security_group.id
  type                     = "egress"
  description              = "Allow EC2 Instance to mount EFS"
  protocol                 = "TCP"
  from_port                = 2049
  to_port                  = 2049
}