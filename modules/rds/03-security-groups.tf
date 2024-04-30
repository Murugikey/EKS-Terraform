resource "aws_security_group" "rds_default_access_sg" {
  name        = "${var.IDENTIFIER}-default-sg"
  description = "RDS Control Access Security Group"
  vpc_id      = var.VPC_ID

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Name"         = "${var.IDENTIFIER}-default-sg"
      "Purpose"      = "RDS Control Access Security Group ${upper(var.DEFAULT_TAGS.Project)} - ${var.IDENTIFIER}"
      "SecurityZone" = "X2"
    },
  )
}


## Inbound/Outbound Rules
resource "aws_security_group_rule" "default_access_rules" {
  count                    = length(var.TRAFFIC_CIDRS_ALLOWED) 
  type                     = var.TRAFFIC_CIDRS_ALLOWED[count.index].type
  description              = "Allow custom ${upper(var.TRAFFIC_CIDRS_ALLOWED[count.index].type)} traffic for ${var.NAME_PREFIX} RDS"
  protocol                 = "TCP"
  security_group_id        = aws_security_group.rds_default_access_sg.id
  cidr_blocks              = var.TRAFFIC_CIDRS_ALLOWED[count.index].cidr
  from_port                = var.TRAFFIC_CIDRS_ALLOWED[count.index].port
  to_port                  = var.TRAFFIC_CIDRS_ALLOWED[count.index].port
}
