resource "aws_security_group" "default_lb_sg" {
  count       = var.TYPE != "network" ? 1 : 0
  name        = "${var.NAME_PREFIX}-lb-default.sg"
  description = "Default Security group access"
  vpc_id      = var.VPC_ID

  tags = merge(
    var.DEFAULT_TAGS,
    {
      "Name"         = "${var.NAME_PREFIX}-lb-default-access.sg"
      "Purpose"      = "ArgoCD Security group access for DevOps - ${upper(var.DEFAULT_TAGS.Project)}"
    },
  )
}

# Custom Traffic Allowed
resource "aws_security_group_rule" "custom_traffic_cidrs_allowed" {
  count                    = var.TYPE != "network" ? length(var.TRAFFIC_CIDRS_ALLOWED): 0
  type                     = var.TRAFFIC_CIDRS_ALLOWED[count.index].type
  description              = "Allow custom ${upper(var.TRAFFIC_CIDRS_ALLOWED[count.index].type)} traffic for ${var.NAME_PREFIX} ALB"
  protocol                 = "TCP"
  security_group_id        = aws_security_group.default_lb_sg[0].id
  cidr_blocks              = var.TRAFFIC_CIDRS_ALLOWED[count.index].cidr
  from_port                = var.TRAFFIC_CIDRS_ALLOWED[count.index].port
  to_port                  = var.TRAFFIC_CIDRS_ALLOWED[count.index].port

  depends_on = [
    aws_security_group.default_lb_sg[0]
  ]
}


resource "aws_security_group_rule" "inbound_custom_sg_allowed" {
  count                    = var.TYPE != "network" ? length(var.INBOUND_SECURITY_GROUPS): 0
  type                     = var.TRAFFIC_CIDRS_ALLOWED[count.index].type
  description              = "Allow custom ${upper(var.TRAFFIC_CIDRS_ALLOWED[count.index].type)} traffic for ${var.NAME_PREFIX} ALB"
  protocol                 = "TCP"
  security_group_id        = var.INBOUND_SECURITY_GROUPS[count.index].id
  source_security_group_id = aws_security_group.default_lb_sg[0].id
  from_port                = var.TRAFFIC_CIDRS_ALLOWED[count.index].port
  to_port                  = var.TRAFFIC_CIDRS_ALLOWED[count.index].port

  depends_on = [
    aws_security_group.default_lb_sg[0]
  ]
}

resource "aws_security_group_rule" "outbound_custom_sg_allowed" {
  count                    = var.TYPE != "network" ? length(var.OUTBOUND_SECURITY_GROUPS): 0
  type                     = var.TRAFFIC_CIDRS_ALLOWED[count.index].type
  description              = "Allow custom ${upper(var.TRAFFIC_CIDRS_ALLOWED[count.index].type)} traffic for ${var.NAME_PREFIX} ALB"
  protocol                 = "TCP"
  security_group_id        = var.OUTBOUND_SECURITY_GROUPS[count.index].id
  source_security_group_id = aws_security_group.default_lb_sg[0].id
  from_port                = var.OUTBOUND_SECURITY_GROUPS[count.index].fromPort
  to_port                  = var.OUTBOUND_SECURITY_GROUPS[count.index].toPort

  depends_on = [
    aws_security_group.default_lb_sg[0]
  ]
}