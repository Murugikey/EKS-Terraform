########################## ##########################
################ VPC FILE Refactor ##################
########################## ##########################


##########################
##### VPC Automation #####
##########################

## VPC ## 
resource "aws_vpc" "vpc" {
  cidr_block           = var.VPC_CIDR_BLOCK
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      "Name"         = "${local.name_prefix}-vpc.${var.vpc_order}"
      "Purpose"      = "VPC to hold ${upper(local.common_tags.Project)}"
      "SecurityZone" = "S2"
    },
  )
}

## Public Subnets ##
resource "aws_subnet" "public_subnets" {
  count = length(var.PUBLIC_SUBNETS)

  vpc_id            = aws_vpc.vpc.id
  availability_zone = element(local.az, var.PUBLIC_SUBNETS[count.index].az)
  cidr_block        = var.PUBLIC_SUBNETS[count.index].cidr

  tags = merge(
    local.common_tags,
    {
      "Purpose"      = "Public subnet ${count.index + 1} for ${upper(local.common_tags.Project)}-${upper(var.PUBLIC_SUBNETS[count.index].description)}"
      "Name"         = "${local.name_prefix}-public-subnet.${var.PUBLIC_SUBNETS[count.index].description}"
      "SecurityZone" = "E-I"
    },
  )
}

## Private Subnets ##
resource "aws_subnet" "private_subnets" {
  count = length(var.PRIVATE_SUBNETS)

  vpc_id            = aws_vpc.vpc.id
  availability_zone = element(local.az, var.PRIVATE_SUBNETS[count.index].az)
  cidr_block        = var.PRIVATE_SUBNETS[count.index].cidr

  tags = merge(
    local.common_tags, 
    {
      "Purpose"      = "Private subnet ${count.index + 1} for ${upper(local.common_tags.Project)}-${upper(var.PRIVATE_SUBNETS[count.index].description)}"
      "Name"         = "${local.name_prefix}-private-subnet-${var.PRIVATE_SUBNETS[count.index].description}"
      "SecurityZone" = "E-I"
    },
  )
}

#########################
######## ROUTING ########
#########################

## GATEWAYS ##

## INTERNET GATEWAY ##
resource "aws_internet_gateway" "internet_igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      "Purpose"      = "IGW for VPC ${upper(local.common_tags.Project)}"
      "Name"         = "${local.name_prefix}-igw"
      "SecurityZone" = "E-I"
    },
  )
}

## NAT GATEWAY A ##
resource "aws_nat_gateway" "ngw" {
  #count = length(local.az)
  #subnet_id     = aws_subnet.public_subnets[count.index].id # -> for future implementation where more than one NAT GW is used between multiple AZs
  subnet_id     = aws_subnet.public_subnets[0].id
  allocation_id = aws_eip.nat_eip.id
  depends_on    = [aws_internet_gateway.internet_igw]

  tags = merge(
    local.common_tags,
    {
      "Purpose"      = "For use with NAT gateway ${upper(local.common_tags.Project)}"
      "Name"         = "${local.name_prefix}-nat-gw"
      "SecurityZone" = "E-O"
    },
  )
}

## ROUTE TABLES ##

## DEFAULT MAIN ROUTE TABLE ##
resource "aws_default_route_table" "default_route_table" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  tags = merge(
    local.common_tags,
    {
      "Purpose"      = "Default route table ${upper(local.common_tags.Project)}"
      "Name"         = "${local.name_prefix}-default-rt"
      "SecurityZone" = "X2"
    },
  )
}

## PUBLIC ROUTE TABLE ##
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      "Purpose"      = "Route to internet for public subnets, via Internet GW ${upper(local.common_tags.Project)}"
      "Name"         = "${local.name_prefix}-public-rtb"
      "SecurityZone" = "X2"
    },
  )
}

## PRIVATE ROUTE TABLE ##
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      "Purpose"      = "Route to Internet GW for private subnet, via NAT GW ${upper(local.common_tags.Project)}"
      "Name"         = "${local.name_prefix}-private-rtb"
      "SecurityZone" = "X2"
    },
  )
}

## ROUTES ##

resource "aws_route" "public_route_to_igw" { # Public route to Internet Gateway
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_igw.id
}

## PRIVATE ROUTE A TO NAT GW ##
resource "aws_route" "private_route_to_nat" { # Private route to NAT Gateway
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  #nat_gateway_id         = aws_nat_gateway.ngw[count.index].id # -> for future implementation where more than one NAT GW is used between multiple AZs
  nat_gateway_id         = aws_nat_gateway.ngw.id
}

##############################
## ROUTE TABLE ASSOCIATIONS ##
##############################

## PUBLIC ROUTE TABLE & SUBNETS ASSOCIATION ##
resource "aws_route_table_association" "public_assoc" {
  count          = length(var.PUBLIC_SUBNETS)
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}

## PRIVATE ROUTE TABLE & SUBNETS ASSOCIATION ##
resource "aws_route_table_association" "pvt_assoc" {
  count          = length(var.PRIVATE_SUBNETS)
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)
}

## NAT GW EIP ##
resource "aws_eip" "nat_eip" {

  tags = merge(
    local.common_tags,
    {
      "Purpose"      = "EIP for NAT gateway ${upper(local.common_tags.Project)}"
      "Name"         = "${local.name_prefix}-nat-gw-eip"
      "SecurityZone" = "E-I"
    },
  )
}

####################
##### DEFAULTS #####
####################

## Default NACL ##
resource "aws_default_network_acl" "nacl_default" {
  default_network_acl_id = aws_vpc.vpc.default_network_acl_id

  #IPv4
  ingress {
    protocol   = -1 #all
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  #IPv6
  ingress {
    protocol        = -1 #all
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  #IPv4
  egress {
    protocol   = -1 #all
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  #IPv6
  egress {
    protocol        = -1 #all
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  tags = merge(
    local.common_tags,
    {
      "Name"         = "${local.name_prefix}-default-nacl"
      "Purpose"      = "Default NACL for ${upper(local.common_tags.Project)}"
      "SecurityZone" = "X2"
    },
  )

}


## DHCP Options ##
resource "aws_vpc_dhcp_options" "default_dhcp_options" {
  domain_name         = "${data.aws_region.current.name}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = merge(
    local.common_tags,
    {
      "Name"         = "DHCP Options Set for ${local.name_prefix}"
      "Purpose"      = "DHCP Options Set ${upper(local.common_tags.Project)}"
      "SecurityZone" = "S2"
    },
  )
}

## DHCP OPTION SET ASSOCIATION ##
resource "aws_vpc_dhcp_options_association" "default_dhcp_options_assoc" {
  vpc_id          = aws_vpc.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.default_dhcp_options.id
}

##########################
###### VPC FLOW LOGS #####
##########################

## VPC Flow logs to S3 ##
resource "aws_flow_log" "flowlog_s3" {
  log_destination      = "arn:aws:s3:::${local.logging_bucket["name"]}"
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.vpc.id
}

## CloudWatch log group ##
resource "aws_cloudwatch_log_group" "vpc_flow_logs_group_01" {
  name              = "/aws/vpc/flow-logs/${aws_vpc.vpc.id}-01"
  retention_in_days = 90
}

## VPC Flow Logs IAM role ##
resource "aws_iam_role" "vpc_flow_logs_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = merge(
    local.common_tags,
    {
      "Purpose" = "Service role used by Flow Logs for deployment VPC for ${upper(local.common_tags.Project)}"
    },
  )
}

## VPC Flow Logs IAM role policy ##
resource "aws_iam_role_policy" "vpc_flow_logs_role_policy" {
  role = aws_iam_role.vpc_flow_logs_role.id
  name = "${local.name_prefix}-vpc-flow-logs-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

## VPC Flow Logs to CloudWatch ##
resource "aws_flow_log" "flowlog_cloudwatch" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs_group_01.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vpc.id
}

resource "aws_default_security_group" "vpc_default_sg" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      "Name"         = "${local.name_prefix}-default-sg"
      "Purpose"      = "Restrict all traffic always ${upper(local.common_tags.Project)} - DO NOT USE"
      "SecurityZone" = "X2"
    },
  )
}

########################## ######################
###### Management Security Group Refactor #######
########################## ######################

## Security Group for TrendMicro VPC Endpoint ##
resource "aws_security_group" "trendmicro_endpoint_sg" {
  name        = "${local.name_prefix}-${data.aws_region.current.name}-trendmicro-endpoint-sg"
  description = "Security group for ${local.name_prefix} for Trendmicro VPC endpoint"
  vpc_id      = aws_vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      "Name"         = "${local.name_prefix}-${data.aws_region.current.name}-trendmicro-endpoint-sg"
      "Purpose"      = "Security group for ${local.name_prefix} for Trendmicro VPC endpoint"
      "SecurityZone" = "X2"
  }, )

}

resource "aws_security_group_rule" "ingress_trendmicro_endpoint_rule" {
  count = length([
    8443,
    443,
    4120,
    4122,
  5275])
  type = "ingress"
  from_port = [
    8443,
    443,
    4120,
    4122,
  5275][count.index]
  to_port = [
    8443,
    443,
    4120,
    4122,
  5275][count.index]
  protocol          = "TCP"
  security_group_id = aws_security_group.trendmicro_endpoint_sg.id
  cidr_blocks       = ["${var.VPC_CIDR_BLOCK}"]
  description       = "VPC CIDR to TrendMicro VPC Endpoint"
  depends_on        = [aws_vpc.vpc]
}

## SSM Endpoints Security Group ##
resource "aws_security_group" "ssm_endpoints_sg" {
  name        = "${local.name_prefix}-${data.aws_region.current.name}-ssm-endpoints-sg"
  description = "Security group for ${local.name_prefix} for SSM VPC endpoints"
  vpc_id      = aws_vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      "Name"         = "${local.name_prefix}-${data.aws_region.current.name}-ssm-endpoints-sg"
      "Purpose"      = "Security group for ${local.name_prefix} for SSM VPC endpoints"
      "SecurityZone" = "X2"
  }, )

}

resource "aws_security_group_rule" "ingress_ssm_endpoints_rule" {
  type              = "ingress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "TCP"
  security_group_id = aws_security_group.ssm_endpoints_sg.id
  cidr_blocks       = ["${var.VPC_CIDR_BLOCK}"]
  description       = "VPC CIDR to SSM VPC Endpoints"
  depends_on        = [aws_vpc.vpc]
}



## Security Group for Trendmicro, SSM and Qualys for Instances ##

resource "aws_security_group" "trendssmqualys_sg" {
  name        = "${local.name_prefix}-${data.aws_region.current.name}-trendssmqualys-sg"
  description = "Security group for ${local.name_prefix} for Trendmicro, SSM and Qualys"
  vpc_id      = aws_vpc.vpc.id
  depends_on        = [aws_vpc.vpc]

  tags = merge(
    local.common_tags,
    {
      "Name"         = "${local.name_prefix}-${data.aws_region.current.name}-trendssmqualys-sg"
      "Purpose"      = "Security group for ${local.name_prefix} for Trendmicro, SSM and Qualys"
      "SecurityZone" = "X2"
    },
  )
}

resource "aws_security_group_rule" "egress_trendmicro_tcp_rule" {
  count = length([
    8443,
    443,
    4120,
    4122,
  5275])
  type = "egress"
  from_port = [
    8443,
    443,
    4120,
    4122,
  5275][count.index]
  to_port = [
    8443,
    443,
    4120,
    4122,
  5275][count.index]
  protocol                 = "tcp"
  security_group_id        = aws_security_group.trendssmqualys_sg.id
  source_security_group_id = aws_security_group.trendmicro_endpoint_sg.id
  description              = "Instance to TrendMicro VPC endpoint"
  depends_on        = [aws_vpc.vpc]
}


resource "aws_security_group_rule" "egress_ssm_https" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.trendssmqualys_sg.id
  source_security_group_id = aws_security_group.ssm_endpoints_sg.id
  description              = "Instance to SSM VPC endpoints"
  depends_on        = [aws_vpc.vpc]
}


resource "aws_security_group_rule" "egress_ssm_s3_prefix_rule" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.trendssmqualys_sg.id
  prefix_list_ids   = [aws_vpc_endpoint.s3_endpoint.prefix_list_id]
  description       = "Instance to S3 VPC endpoint Prefix List"
  depends_on        = [aws_vpc.vpc]
}


resource "aws_security_group_rule" "egress_qualys_https_rule" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.trendssmqualys_sg.id
  cidr_blocks       = ["64.39.106.0/24", "154.59.121.0/24"]
  description       = "Instance to Qualys External endpoint"
  depends_on        = [aws_vpc.vpc]
}

######################### ##########################
########### VPC Endpoints Refactoring ##############
######################### ##########################
# VPC endpoint for TrendMicro ##
resource "aws_vpc_endpoint" "trendmicro_endpoint" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.vpce.${data.aws_region.current.name}.${var.TrendMicroSvcName}"
  vpc_endpoint_type = "Interface"

  security_group_ids = ["${aws_security_group.trendmicro_endpoint_sg.id}"]

  ## 2 public subnets are required for this to work
  subnet_ids          = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      "Purpose"      = "TrendMicro VPC Endpoint for ${local.name_prefix} Project"
      "Name"         = "vgsl-mps.${local.name_prefix}-${data.aws_region.current.name}-trendmicro-vpc-endpoint"
      "SecurityZone" = "X2"
    },
  )
}


## VPC endpoint for ssm ##
resource "aws_vpc_endpoint" "ssm_endpoint" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = ["${aws_security_group.ssm_endpoints_sg.id}"]

  ## 2 public subnets are required for this to work
  subnet_ids          = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      "Purpose"      = "SSM VPC Endpoint for ${local.name_prefix} Project"
      "Name"         = "${local.name_prefix}-${data.aws_region.current.name}-ssm-vpc-endpoint"
      "SecurityZone" = "X2"
    },
  )
}


## VPC endpoint for ssm messages ##
resource "aws_vpc_endpoint" "ssm_messages_endpoint" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type = "Interface"

  security_group_ids = ["${aws_security_group.ssm_endpoints_sg.id}"]

  ## 2 public subnets are required for this to work
  subnet_ids          = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      "Purpose"      = "SSM Messages VPC Endpoint for ${local.name_prefix} Project"
      "Name"         = "${local.name_prefix}-${data.aws_region.current.name}-ssmmessages-vpc-endpoint"
      "SecurityZone" = "X2"
    },
  )
}


## VPC endpoint for ec2messages ##
resource "aws_vpc_endpoint" "ec2_messages_endpoint" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type = "Interface"

  security_group_ids = ["${aws_security_group.ssm_endpoints_sg.id}"]

  ## 2 public subnets are required for this to work
  subnet_ids          = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      "Purpose"      = "EC2 Messages VPC Endpoint for ${local.name_prefix} Project"
      "Name"         = "${local.name_prefix}-${data.aws_region.current.name}-ec2messages-vpc-endpoint"
      "SecurityZone" = "X2"
    },
  )
}


## VPC endpoint for S3 ##
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  tags = merge(
    local.common_tags,
    {
      "Purpose"      = "S3 Gateway VPC Endpoint for ${local.name_prefix} Project"
      "Name"         = "${local.name_prefix}-${data.aws_region.current.name}-s3-vpc-endpoint"
      "SecurityZone" = "X2"
    },
  )
}

## Associate route table with VPC endpoint ##
resource "aws_vpc_endpoint_route_table_association" "s3_endpoint_route_association" {
  count  = length(var.PUBLIC_SUBNETS)
  route_table_id  = aws_route_table.public_route_table.id
  vpc_endpoint_id = aws_vpc_endpoint.s3_endpoint.id
}


resource "aws_route" "public_a_peering_route_mpa_dev" {
  route_table_id            = aws_route_table.private_route_table.id
  destination_cidr_block    = var.VPC_PEER_SETTINGS_SFCNONPRODSS.PEER_VPC_CIDR_BLOCK
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering_connection_sfcnonprodss.id
  depends_on                = [aws_vpc_peering_connection.vpc_peering_connection_sfcnonprodss]
}

resource "aws_route" "public_a_peering_route_shared_secrets" {
  route_table_id            = aws_route_table.private_route_table.id
  destination_cidr_block    = var.VPC_PEER_SETTINGS_SHARED_SERVICES.PEER_VPC_CIDR_BLOCK
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering_connection_shared_services.id
  depends_on                = [aws_vpc_peering_connection.vpc_peering_connection_shared_services]
}