module "ec2_comms_rabbit" {
  source = "../modules/ec2/"

  NAME_PREFIX       = local.name_prefix
  TYPE              = var.EC2_TYPE
  TAG_NAME          = var.RABBIT_TAG_NAME
  DEFAULT_TAGS      = local.common_tags
  VPC_ID            = aws_vpc.vpc.id
  INSTANCE_FUNCTION = "comms-rabbit"
  SUBNET_LIST       = [aws_subnet.private_subnets[3].id, aws_subnet.private_subnets[4].id, aws_subnet.private_subnets[5].id]

  CREATE_INSTANCE_PROFILE = true

  VPC_CIDR = var.VPC_CIDR_BLOCK

  INSTANCE_DEFINITIONS = merge(var.default_ec2_definition,
    {
      ami              = "ami-07e9b01bc5d0ce147" #vgsl-mps.mpesa-superapp-dev-eu-west-1-comms-rabbit-base	531477563173/vgsl-mps.mpesa-superapp-dev-eu-west-1-comms-rabbit-base
      instance_type    = "t3a.small"
      root_volume_size = 100
  })

  AUTHORIZED_EC2_CIDRS = [
    { type : "egress", cidr : ["0.0.0.0/0"], to_port : 443, from_port : 443, protocol : "TCP", description : "SSM Access" }, # For SSM Access

    { type : "ingress", cidr : [aws_subnet.private_subnets[3].cidr_block, aws_subnet.private_subnets[4].cidr_block, aws_subnet.private_subnets[5].cidr_block], protocol : "TCP", from_port : var.RABBIT_PORT, to_port : var.RABBIT_PORT, "description" : "RabbitMQ" }, # RabbitMQ in
    { type : "egress", cidr : [aws_subnet.private_subnets[3].cidr_block, aws_subnet.private_subnets[4].cidr_block, aws_subnet.private_subnets[5].cidr_block], protocol : "TCP", from_port : var.RABBIT_PORT, to_port : var.RABBIT_PORT, "description" : "RabbitMQ" },  # RabbitMQ out

    { type : "ingress", cidr : [aws_subnet.private_subnets[3].cidr_block, aws_subnet.private_subnets[4].cidr_block, aws_subnet.private_subnets[5].cidr_block], protocol : "TCP", from_port : var.RABBIT_EPMD_PORT, to_port : var.RABBIT_EPMD_PORT, "description" : "RabbitMQ Service Discovery" }, # RabbitMQ EPMD in
    { type : "egress", cidr : [aws_subnet.private_subnets[3].cidr_block, aws_subnet.private_subnets[4].cidr_block, aws_subnet.private_subnets[5].cidr_block], protocol : "TCP", from_port : var.RABBIT_EPMD_PORT, to_port : var.RABBIT_EPMD_PORT, "description" : "RabbitMQ Service Discovery" },  # RabbitMQ EPMD out

    { type : "egress", cidr : [aws_subnet.private_subnets[3].cidr_block, aws_subnet.private_subnets[4].cidr_block, aws_subnet.private_subnets[5].cidr_block], protocol : "TCP", from_port : 25672, to_port : 25672, "description" : "RabbitMQ Cluster Egress" },  # RabbitMQ EPMD Egress
    { type : "ingress", cidr : [aws_subnet.private_subnets[3].cidr_block, aws_subnet.private_subnets[4].cidr_block, aws_subnet.private_subnets[5].cidr_block], protocol : "TCP", from_port : 25672, to_port : 25672, "description" : "RabbitMQ Cluster Ingress" } # RabbitMQ EPMD Ingress
  ]

  AUTHORIZED_EC2_SG = [
    { type : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.RABBIT_PORT, to_port : var.RABBIT_PORT, "description" : "RabbitMQ" }, # RabbitMQ in
    { type : "egress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.RABBIT_PORT, to_port : var.RABBIT_PORT, "description" : "RabbitMQ" },  # RabbitMQ out

    { type : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.RABBIT_EPMD_PORT, to_port : var.RABBIT_EPMD_PORT, "description" : "RabbitMQ Service Discovery" }, # RabbitMQ EPMD in
    { type : "egress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.RABBIT_EPMD_PORT, to_port : var.RABBIT_EPMD_PORT, "description" : "RabbitMQ Service Discovery" },  # RabbitMQ EPMD out

    { type : "egress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : 25672, to_port : 25672, "description" : "RabbitMQ Cluster Egress" },  # RabbitMQ EPMD Egress
    { type : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : 25672, to_port : 25672, "description" : "RabbitMQ Cluster Ingress" } # RabbitMQ EPMD Ingress
  ]

  AWS_IAM_POLICIES = [
    "AmazonSSMManagedInstanceCore",
    "CloudWatchAgentServerPolicy",
    "AWSCloudFormationReadOnlyAccess"
  ]

  CUSTOM_IAM_POLICIES = [
    aws_iam_policy.default_ec2_policy
  ]

  VENDOR_ROLE = "DevOps4"
}

module "ec2_comms_hz" {
  source = "../modules/ec2/"

  NAME_PREFIX       = local.name_prefix
  TYPE              = "EC2"
  TAG_NAME          = "comms-hz"
  DEFAULT_TAGS      = local.common_tags
  INSTANCE_FUNCTION = "comms-hz"
  VPC_ID            = aws_vpc.vpc.id
  SUBNET_LIST       = [aws_subnet.private_subnets[3].id, aws_subnet.private_subnets[4].id, aws_subnet.private_subnets[5].id]

  VPC_CIDR = var.VPC_CIDR_BLOCK

  CREATE_INSTANCE_PROFILE = true

  INSTANCE_DEFINITIONS = merge(var.default_ec2_definition,
    {
      ami              = "ami-0f69c19420bd63a45" #vgsl-mps.mpesa-superapp-dev-eu-west-1-comms-hz-base	531477563173/vgsl-mps.mpesa-superapp-dev-eu-west-1-comms-hz-base
      instance_type    = "t3a.small"
      root_volume_size = 100
      subnet           = "private"

  })

  AUTHORIZED_EC2_CIDRS = [
    { type : "egress", cidr : ["0.0.0.0/0"], protocol : "TCP", from_port : 443, to_port : 443, description : "SSM Access" }, # For SSM Access
    { type : "egress", cidr : [aws_subnet.private_subnets[3].cidr_block, aws_subnet.private_subnets[4].cidr_block, aws_subnet.private_subnets[5].cidr_block], protocol : "TCP", from_port : var.HZ_PORT, to_port : var.HZ_PORT, description : "HZ Communication between nodes" },
    { type : "ingress", cidr : [aws_subnet.private_subnets[3].cidr_block, aws_subnet.private_subnets[4].cidr_block, aws_subnet.private_subnets[5].cidr_block], protocol : "TCP", from_port : var.HZ_PORT, to_port : var.HZ_PORT, description : "HZ Communication between nodes" }
  ]

  AUTHORIZED_EC2_SG = [
    { type : "egress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.HZ_PORT, to_port : var.HZ_PORT, "description" : "Hazelcast In" },  # Hazelcast in
    { type : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.HZ_PORT, to_port : var.HZ_PORT, "description" : "Hazelcast Out" } # Hazelcast out
  ]

  AWS_IAM_POLICIES = [
    "AmazonSSMManagedInstanceCore",
    "CloudWatchAgentServerPolicy",
    "AWSCloudFormationReadOnlyAccess"
  ]

  CUSTOM_IAM_POLICIES = [
    aws_iam_policy.default_ec2_policy
  ]

  VENDOR_ROLE = "DevOps4"
}

#module "ec2_comms_open_vpn" {
#  source = "../modules/ec2/"
#
#  NAME_PREFIX             = local.name_prefix
#  TYPE                    = "EC2"
#  TAG_NAME                = "comms-open-vpn"
#  DEFAULT_TAGS            = local.common_tags
#  INSTANCE_FUNCTION       = "comms-open-vpn"
#  VPC_ID                  = aws_vpc.vpc.id
#  SUBNET_LIST             = [aws_subnet.private_subnets[9].id]
#
#  VPC_CIDR                = var.VPC_CIDR_BLOCK
#  CREATE_INSTANCE_PROFILE = true
# 
#  INSTANCE_DEFINITIONS    = merge(var.default_ec2_definition, 
#    {
#      ami              = "ami-0f69c19420bd63a45" #vgsl-mps.mpesa-superapp-dev-eu-west-1-comms-hz-base	531477563173/vgsl-mps.mpesa-superapp-dev-eu-west-1-comms-hz-base
#      instance_type    = "t3a.small"
#      root_volume_size = 100
#      subnet           = "private"
#    })
#  AUTHORIZED_EC2_CIDRS  = [
#    { type : "egress", cidr : ["0.0.0.0/0"], from_port : 443,   to_port : 443,   description : "SSM Access" }, # SSH Access (From WIT MPA)
#    { type : "egress", cidr : [var.VPC_CIDR_BLOCK], from_port : 2049,   to_port : 2049,   description : "SSM Access" }, # SSH Access (From WIT MPA)
#    { type : "egress", cidr : ["${var.VDF_VDFSVC_OUTGOING_IP[1]}/32"], from_port : var.VDF_VDFSVC_OUTGOING_PORTS[1],      to_port : var.VDF_VDFSVC_OUTGOING_PORTS[1],      description : var.VDF_VDFSVC_OUTGOING_PORTS_DESC[1] }, 
#    { type : "egress", cidr : ["${var.VDF_VDFSVC_OUTGOING_IP[2]}/32"], from_port : var.VDF_VDFSVC_OUTGOING_PORTS[2],      to_port : var.VDF_VDFSVC_OUTGOING_PORTS[2],      description : var.VDF_VDFSVC_OUTGOING_PORTS_DESC[2] },
#    { type : "egress", cidr : ["${var.VDF_VDFSVC_OUTGOING_IP[0]}/32"], from_port : var.VDF_VDFSVC_OUTGOING_PORTS[0],      to_port : var.VDF_VDFSVC_OUTGOING_PORTS[0],      description : var.VDF_VDFSVC_OUTGOING_PORTS_DESC[0] },
#    { type : "egress", cidr : ["${var.VDF_VDFSVC_OUTGOING_IP[3]}/32"], from_port : var.VDF_VDFSVC_OUTGOING_PORTS[3],      to_port : var.VDF_VDFSVC_OUTGOING_PORTS[3],      description : var.VDF_VDFSVC_OUTGOING_PORTS_DESC[3] },
#    { type : "egress", cidr : ["${var.VPNPROXY_IP}/32"],               from_port : var.VDF_INTEGRATION_OUTGOING_PORTS[1], to_port : var.VDF_INTEGRATION_OUTGOING_PORTS[1], description : var.VDF_INTEGRATION_OUTGOING_PORTS_DESC[1] },
#    { type : "egress", cidr : ["${var.VPNPROXY_IP}/32"],               from_port : var.VDF_INTEGRATION_OUTGOING_PORTS[0], to_port : var.VDF_INTEGRATION_OUTGOING_PORTS[0], description : var.VDF_INTEGRATION_OUTGOING_PORTS_DESC[0] },
#    { type : "egress", cidr : ["${var.VPNPROXY_IP}/32"],               from_port : var.VDF_INTEGRATION_OUTGOING_PORTS[2], to_port : var.VDF_INTEGRATION_OUTGOING_PORTS[2], description : var.VDF_INTEGRATION_OUTGOING_PORTS_DESC[2] },
#    { type : "egress", cidr : ["${var.VPNPROXY_IP}/32"],               from_port : var.VDF_INTEGRATION_OUTGOING_PORTS[3], to_port : var.VDF_INTEGRATION_OUTGOING_PORTS[3], description : var.VDF_INTEGRATION_OUTGOING_PORTS_DESC[3] },
#  ]
#  AWS_IAM_POLICIES   = [
#    "AmazonSSMManagedInstanceCore",
#    "CloudWatchAgentServerPolicy",
#    "AWSCloudFormationReadOnlyAccess"
#  ]
#  
#  CUSTOM_IAM_POLICIES = [
#    aws_iam_policy.default_ec2_policy
#  ]
#  VENDOR_ROLE          = "DevOps4"
#}

#module "asg_comms" {
#  source = "../modules/ec2/"
#
#  ASG_DESIRED           = var.ASG_DESIRED
#  ASG_MAX               = var.ASG_MAX
#  ASG_MIN               = var.ASG_MIN
#  ASG_FORCE_DELETE      = var.ASG_FORCE_DELETE
#  ASG_HEALTH_CHECK      = var.ASG_HEALTH_CHECK
#  UPDATE_ASG            = var.UPDATE_ASG
#
#  NAME_PREFIX           = local.name_prefix
#  TYPE                  = "ASG"
#  TAG_NAME              = "comms"
#  DEFAULT_TAGS          = local.common_tags
#  INSTANCE_FUNCTION     = "COMMS" # If instance is bastion, comms or proxy
#  VPC_ID                = aws_vpc.vpc.id
#  VPC_CIDR              = var.VPC_CIDR_BLOCK
#  SUBNET_LIST           = [aws_subnet.private_subnets[3].id, aws_subnet.private_subnets[4].id, aws_subnet.private_subnets[5].id]
#
#  CREATE_INSTANCE_PROFILE = true
#
#  INSTANCE_DEFINITIONS = merge(var.default_ec2_definition, 
#    {
#      instance_type    = "t3a.small"
#      root_volume_size = 100
#      subnet           = "private"
#      index            = 0
#      hostnum          = 5
#    })
#
#  AUTHORIZED_EC2_CIDRS  = [
#    { type : "egress",  cidr : ["0.0.0.0/0"], from_port : 443,  to_port : 443,  description : "SSM Access" }, # SSH Access (From WIT MPA)
#    { type : "egress",  cidr : [var.VPC_CIDR_BLOCK], from_port : 2049,  to_port : 2049,  description : "EFS Access" }#, # SSH Access (From WIT MPA)
#    #{ type : "ingress",  cidr : ["0.0.0.0/0"], from_port : 2049,  to_port : 2049,  description : "SSM Access" }#, # SSH Access (From WIT MPA)
#    #{ type : "ingress", cidr : var.WIT_CIDRS, from_port : 2222, to_port : 2222, description : "SSH Access" }, # SSH Access (From WIT MPA)
#    #{ type : "ingress", cidr : var.WIT_CIDRS, from_port : 9991, to_port : 9991, description : "ArgoCD Service" }, # ArgoCD Service (From WIT Devs)
#    #{ type : "ingress", cidr : var.WIT_CIDRS, from_port : 9992, to_port : 9992, description : "Grafana Dashboard" }, # Grafana Dashboards (From WIT Devs)
#    #{ type : "egress", cidr : var.WIT_CIDRS, from_port : 443, to_port : 443, description : "SSM Access" }#, # Grafana Dashboards (From WIT Devs)
#
#    #{ "type" : "egress", "cidr" : module.vpc.private_subnet_cidrs, "port" : var.MONGO_PORT, "description" : "Mongo DB" },
#    #{ "type" : "egress", "cidr" : module.vpc.private_subnet_cidrs, "port" : var.POSTGRES_PORT, "description" : "Postgres" },
#    #{ "type" : "egress", "cidr" : module.vpc.private_subnet_cidrs, "port" : 30081, "description" : "ArgoCD"  }, # ArgoCD Service (to LB)
#    #{ "type" : "egress", "cidr" : module.vpc.private_subnet_cidrs, "port" : 30082, "description" : "Grafana"  } # Grafana dashboards (to LB)
#  ]
#
#  AUTHORIZED_EC2_SG = [
#    { type : "ingress", security_group_id = module.ec2_proxies.security_group, to_port : 2222, from_port : 2222, description : "SSH Access" }
#  ]
#
#  EFS_SECURITY_GROUP = module.shared_efs.efs_default_sg
#
#  AWS_IAM_POLICIES            = [
#    "AmazonSSMManagedInstanceCore",
#    "CloudWatchAgentServerPolicy",
#    "AWSCloudFormationReadOnlyAccess"
#  ]
#
#  CUSTOM_IAM_POLICIES         = [
#    aws_iam_policy.default_ec2_policy
#  ]
#  
#  VENDOR_ROLE                     = "q"
#
#  depends_on              = [
#    module.shared_efs
#  ]
#} 


module "asg_proxy" {
  source = "../modules/ec2/"

  CUSTOM_USERDATA_FILENAME = "custom-proxy-userdata.tpl"
  EFS_DNS                  = module.shared_efs.dns_name
  ASG_DESIRED              = var.ASG_DESIRED
  ASG_MAX                  = var.ASG_MAX
  ASG_MIN                  = var.ASG_MIN
  ASG_FORCE_DELETE         = var.ASG_FORCE_DELETE
  ASG_HEALTH_CHECK         = var.ASG_HEALTH_CHECK
  UPDATE_ASG               = var.UPDATE_ASG

  ASG_LIFECYCLE     = "ON DEMAND"
  NAME_PREFIX       = local.name_prefix
  TYPE              = "ASG"
  TAG_NAME          = "proxy"
  DEFAULT_TAGS      = local.common_tags
  INSTANCE_FUNCTION = "PROXY" # If instance is bastion, comms or proxy
  VPC_ID            = aws_vpc.vpc.id
  VPC_CIDR          = var.VPC_CIDR_BLOCK
  SUBNET_LIST       = [aws_subnet.private_subnets[9].id, aws_subnet.private_subnets[10].id, aws_subnet.private_subnets[11].id]

  CREATE_INSTANCE_PROFILE = true

  INSTANCE_DEFINITIONS = merge(var.default_ec2_definition,
    {
      ami              = "ami-000f1512f78b5d1bc"
      instance_type    = "t3a.micro"
      root_volume_size = 50
      subnet           = "private"
      index            = 0
      hostnum          = 3
  })

  AUTHORIZED_EC2_CIDRS = [
    { type : "egress", cidr : ["0.0.0.0/0"], protocol : "TCP", from_port : 443, to_port : 443, description : "SSM Access" },          # SSH Access (From WIT MPA)
    { type : "egress", cidr : [var.VPC_CIDR_BLOCK], protocol : "TCP", from_port : 2049, to_port : 2049, description : "SSM Access" }, # SSH Access (From WIT MPA)
    { type : "egress", cidr : ["${var.VDF_VDFSVC_OUTGOING_IP[1]}/32"], protocol : "TCP", from_port : var.VDF_VDFSVC_OUTGOING_PORTS[1], to_port : var.VDF_VDFSVC_OUTGOING_PORTS[1], description : var.VDF_VDFSVC_OUTGOING_PORTS_DESC[1] },
    { type : "egress", cidr : ["${var.VDF_VDFSVC_OUTGOING_IP[2]}/32"], protocol : "TCP", from_port : var.VDF_VDFSVC_OUTGOING_PORTS[2], to_port : var.VDF_VDFSVC_OUTGOING_PORTS[2], description : var.VDF_VDFSVC_OUTGOING_PORTS_DESC[2] },
    { type : "egress", cidr : ["${var.VDF_VDFSVC_OUTGOING_IP[0]}/32"], protocol : "TCP", from_port : var.VDF_VDFSVC_OUTGOING_PORTS[0], to_port : var.VDF_VDFSVC_OUTGOING_PORTS[0], description : var.VDF_VDFSVC_OUTGOING_PORTS_DESC[0] },
    { type : "egress", cidr : ["${var.VDF_VDFSVC_OUTGOING_IP[3]}/32"], protocol : "TCP", from_port : var.VDF_VDFSVC_OUTGOING_PORTS[3], to_port : var.VDF_VDFSVC_OUTGOING_PORTS[3], description : var.VDF_VDFSVC_OUTGOING_PORTS_DESC[3] },
    { type : "egress", cidr : ["${var.VPNPROXY_IP}/32"], protocol : "TCP", from_port : var.VDF_INTEGRATION_OUTGOING_PORTS[1], to_port : var.VDF_INTEGRATION_OUTGOING_PORTS[1], description : var.VDF_INTEGRATION_OUTGOING_PORTS_DESC[1] },
    { type : "egress", cidr : ["${var.VPNPROXY_IP}/32"], protocol : "TCP", from_port : var.VDF_INTEGRATION_OUTGOING_PORTS[0], to_port : var.VDF_INTEGRATION_OUTGOING_PORTS[0], description : var.VDF_INTEGRATION_OUTGOING_PORTS_DESC[0] },
    { type : "egress", cidr : ["${var.VPNPROXY_IP}/32"], protocol : "TCP", from_port : var.VDF_INTEGRATION_OUTGOING_PORTS[2], to_port : var.VDF_INTEGRATION_OUTGOING_PORTS[2], description : var.VDF_INTEGRATION_OUTGOING_PORTS_DESC[2] },
    { type : "egress", cidr : ["${var.VPNPROXY_IP}/32"], protocol : "TCP", from_port : var.VDF_INTEGRATION_OUTGOING_PORTS[3], to_port : var.VDF_INTEGRATION_OUTGOING_PORTS[3], description : var.VDF_INTEGRATION_OUTGOING_PORTS_DESC[3] },
    { type : "egress", cidr : [var.VPC_PEER_SETTINGS_SFCNONPRODSS.PEER_VPC_CIDR_BLOCK], protocol : "TCP", from_port : "8084", to_port : "8084", description : "Outgoing access to SFCVPNNonProd 8084" },
    { type : "ingress", cidr : ["0.0.0.0/0"], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[8], to_port : var.APP_OUTGOING_PORTS[8], description : var.APP_OUTGOING_PORTS_DESC[8] }, #g2 result inbound from everywhere; to fix: var.VPC_PEER_SETTINGS_SFCNONPRODSS.VPC_CIDR_BLOCK
    { type : "ingress", cidr : ["0.0.0.0/0"], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[10], to_port : var.APP_OUTGOING_PORTS[10], description : var.APP_OUTGOING_PORTS_DESC[10] }, #g2 result inbound from everywhere; to fix: var.VPC_PEER_SETTINGS_SFCNONPRODSS.VPC_CIDR_BLOCK
    { type : "egress", cidr : ["0.0.0.0/0"], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[9], to_port : var.APP_OUTGOING_PORTS[9], description : var.APP_OUTGOING_PORTS_DESC[9] }, #g2 result inbound from everywhere; to fix: var.VPC_PEER_SETTINGS_SFCNONPRODSS.VPC_CIDR_BLOCK
    { type : "ingress", cidr : [var.VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[0], to_port : var.APP_OUTGOING_PORTS[0], description : var.APP_OUTGOING_PORTS_DESC[0] },
    { type : "ingress", cidr : [var.VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[1], to_port : var.APP_OUTGOING_PORTS[1], description : var.APP_OUTGOING_PORTS_DESC[1] },
    { type : "ingress", cidr : [var.VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[2], to_port : var.APP_OUTGOING_PORTS[2], description : var.APP_OUTGOING_PORTS_DESC[2] },
    { type : "ingress", cidr : [var.VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[3], to_port : var.APP_OUTGOING_PORTS[3], description : var.APP_OUTGOING_PORTS_DESC[3] },
    { type : "ingress", cidr : [var.VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[4], to_port : var.APP_OUTGOING_PORTS[4], description : var.APP_OUTGOING_PORTS_DESC[4] },
    { type : "ingress", cidr : [var.VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[5], to_port : var.APP_OUTGOING_PORTS[5], description : var.APP_OUTGOING_PORTS_DESC[5] },
    { type : "ingress", cidr : [var.VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[11], to_port : var.APP_OUTGOING_PORTS[11], description : var.APP_OUTGOING_PORTS_DESC[11] },  # Chat EjabberD C2S
    { type : "ingress", cidr : [var.VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[12], to_port : var.APP_OUTGOING_PORTS[12], description : var.APP_OUTGOING_PORTS_DESC[12] },  # Chat EjabberD HTTPS
    { type : "ingress", cidr : [var.VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[13], to_port : var.APP_OUTGOING_PORTS[13], description : var.APP_OUTGOING_PORTS_DESC[13] },  # Chat EjabberD Service
    { type : "ingress", cidr : [var.VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[14], to_port : var.APP_OUTGOING_PORTS[14], description : var.APP_OUTGOING_PORTS_DESC[14] },  # Chat EjabberD HTTP
    { type : "ingress", cidr : [var.VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[15], to_port : var.APP_OUTGOING_PORTS[15], description : var.APP_OUTGOING_PORTS_DESC[15] },  # Chat Cantaloupe Service
    { type : "ingress", cidr : [var.VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[16], to_port : var.APP_OUTGOING_PORTS[16], description : var.APP_OUTGOING_PORTS_DESC[16] },  # Chat Cantaloupe Upload    
    { type : "egress",  cidr : [var.VPC_PEER_SETTINGS_SHARED_SERVICES.PEER_VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[11], to_port : var.APP_OUTGOING_PORTS[11], description : var.APP_OUTGOING_PORTS_DESC[11] },  # Chat EjabberD C2S
    { type : "egress",  cidr : [var.VPC_PEER_SETTINGS_SHARED_SERVICES.PEER_VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[12], to_port : var.APP_OUTGOING_PORTS[12], description : var.APP_OUTGOING_PORTS_DESC[12] },  # Chat EjabberD HTTPS
    { type : "egress",  cidr : [var.VPC_PEER_SETTINGS_SHARED_SERVICES.PEER_VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[13], to_port : var.APP_OUTGOING_PORTS[13], description : var.APP_OUTGOING_PORTS_DESC[13] },  # Chat EjabberD Service
    { type : "egress",  cidr : [var.VPC_PEER_SETTINGS_SHARED_SERVICES.PEER_VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[14], to_port : var.APP_OUTGOING_PORTS[14], description : var.APP_OUTGOING_PORTS_DESC[14] },  # Chat EjabberD HTTP
    { type : "egress",  cidr : [var.VPC_PEER_SETTINGS_SHARED_SERVICES.PEER_VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[15], to_port : var.APP_OUTGOING_PORTS[15], description : var.APP_OUTGOING_PORTS_DESC[15] },  # Chat Cantaloupe Service
    { type : "egress",  cidr : [var.VPC_PEER_SETTINGS_SHARED_SERVICES.PEER_VPC_CIDR_BLOCK], protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[16], to_port : var.APP_OUTGOING_PORTS[16], description : var.APP_OUTGOING_PORTS_DESC[16] }   # Chat Cantaloupe Upload    

  ]

  AUTHORIZED_EC2_SG = [
    { "type" : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[0], to_port : var.APP_OUTGOING_PORTS[0], description : var.APP_OUTGOING_PORTS_DESC[0] },
    { "type" : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[1], to_port : var.APP_OUTGOING_PORTS[1], description : var.APP_OUTGOING_PORTS_DESC[1] },
    { "type" : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[2], to_port : var.APP_OUTGOING_PORTS[2], description : var.APP_OUTGOING_PORTS_DESC[2] },
    { "type" : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[3], to_port : var.APP_OUTGOING_PORTS[3], description : var.APP_OUTGOING_PORTS_DESC[3] },
    { "type" : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[4], to_port : var.APP_OUTGOING_PORTS[4], description : var.APP_OUTGOING_PORTS_DESC[4] },
    { "type" : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[5], to_port : var.APP_OUTGOING_PORTS[5], description : var.APP_OUTGOING_PORTS_DESC[5] },
    { "type" : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[6], to_port : var.APP_OUTGOING_PORTS[6], description : var.APP_OUTGOING_PORTS_DESC[6] },
    { "type" : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[7], to_port : var.APP_OUTGOING_PORTS[7], description : var.APP_OUTGOING_PORTS_DESC[7] },
    { "type" : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[8], to_port : var.APP_OUTGOING_PORTS[8], description : var.APP_OUTGOING_PORTS_DESC[8] },
    { "type" : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[10], to_port : var.APP_OUTGOING_PORTS[10], description : var.APP_OUTGOING_PORTS_DESC[10] },
    { "type" : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[11], to_port : var.APP_OUTGOING_PORTS[11], description : var.APP_OUTGOING_PORTS_DESC[11] },  # Chat EjabberD C2S
    { "type" : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[12], to_port : var.APP_OUTGOING_PORTS[12], description : var.APP_OUTGOING_PORTS_DESC[12] },  # Chat EjabberD HTTPS
    { "type" : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[13], to_port : var.APP_OUTGOING_PORTS[13], description : var.APP_OUTGOING_PORTS_DESC[13] },  # Chat EjabberD Service
    { "type" : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[14], to_port : var.APP_OUTGOING_PORTS[14], description : var.APP_OUTGOING_PORTS_DESC[14] },  # Chat EjabberD HTTP
    { "type" : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[15], to_port : var.APP_OUTGOING_PORTS[15], description : var.APP_OUTGOING_PORTS_DESC[15] },  # Chat Cantaloupe Service
    { "type" : "ingress", security_group_id : module.eks.eks_cluster_worker_node_sg, protocol : "TCP", from_port : var.APP_OUTGOING_PORTS[16], to_port : var.APP_OUTGOING_PORTS[16], description : var.APP_OUTGOING_PORTS_DESC[16] }   # Chat Cantaloupe Upload
  ]

  EFS_SECURITY_GROUP = module.shared_efs.efs_default_sg

  AWS_IAM_POLICIES = [
    "AmazonSSMManagedInstanceCore",
    "CloudWatchAgentServerPolicy",
    "AWSCloudFormationReadOnlyAccess"
  ]

  CUSTOM_IAM_POLICIES = [
    aws_iam_policy.default_ec2_policy
  ]

  VENDOR_ROLE = "q"

  depends_on = [
    module.shared_efs
  ]
}

module "proxy_nlb" {
  source = "../modules/loadbalancer_asg/"

  NAME_PREFIX  = local.name_prefix
  DEFAULT_TAGS = local.common_tags
  IDENTIFIER   = "${var.ProjectName}-${var.ENV}-prxy-nlb"

  TYPE        = "network"
  ACCESS_TYPE = "private"
  CROSS_ZONE  = true
  VPC_ID   = aws_vpc.vpc.id
  VPC_CIDR = var.VPC_CIDR_BLOCK

  ACCESS_LOGS_BUCKET_ID = module.s3iam.access_logs_bucket_id

  SUBNETS = { private : [aws_subnet.private_subnets[9].id, aws_subnet.private_subnets[10].id, aws_subnet.private_subnets[11].id], public : [] }

  LOGGING_BUCKET_NAME = "proxy-server-nlb-logs"


  TARGETS = [
    { index : 0, name : "tg-1", protocol : "TCP", port : var.APP_OUTGOING_PORTS[0], healthcheck : { port : var.APP_OUTGOING_PORTS[0], path : "", matcher : "" } },
    { index : 1, name : "tg-2", protocol : "TCP", port : var.APP_OUTGOING_PORTS[1], healthcheck : { port : var.APP_OUTGOING_PORTS[1], path : "", matcher : "" } },
    { index : 2, name : "tg-3", protocol : "TCP", port : var.APP_OUTGOING_PORTS[2], healthcheck : { port : var.APP_OUTGOING_PORTS[2], path : "", matcher : "" } },
    { index : 3, name : "tg-4", protocol : "TCP", port : var.APP_OUTGOING_PORTS[3], healthcheck : { port : var.APP_OUTGOING_PORTS[3], path : "", matcher : "" } },
    { index : 4, name : "tg-5", protocol : "TCP", port : var.APP_OUTGOING_PORTS[4], healthcheck : { port : var.APP_OUTGOING_PORTS[4], path : "", matcher : "" } },
    { index : 5, name : "tg-6", protocol : "TCP", port : var.APP_OUTGOING_PORTS[5], healthcheck : { port : var.APP_OUTGOING_PORTS[5], path : "", matcher : "" } },
    { index : 6, name : "tg-7", protocol : "TCP", port : var.APP_OUTGOING_PORTS[6], healthcheck : { port : var.APP_OUTGOING_PORTS[6], path : "", matcher : "" } },
    { index : 7, name : "tg-8", protocol : "TCP", port : var.APP_OUTGOING_PORTS[7], healthcheck : { port : var.APP_OUTGOING_PORTS[7], path : "", matcher : "" } },
    { index : 8, name : "tg-9", protocol : "TCP", port : var.APP_OUTGOING_PORTS[8], healthcheck : { port : var.APP_OUTGOING_PORTS[8], path : "", matcher : "" } },
    { index : 9, name : "tg10", protocol : "TCP", port : var.APP_OUTGOING_PORTS[10], healthcheck : { port : var.APP_OUTGOING_PORTS[10], path : "", matcher : "" } },
    { index : 10, name : "tg11", protocol : "TCP", port : var.APP_OUTGOING_PORTS[11], healthcheck : { port : var.APP_OUTGOING_PORTS[11], path : "", matcher : "" } },  # Chat EjabberD C2S
    { index : 11, name : "tg12", protocol : "TCP", port : var.APP_OUTGOING_PORTS[12], healthcheck : { port : var.APP_OUTGOING_PORTS[12], path : "", matcher : "" } },  # Chat EjabberD HTTPS
    { index : 12, name : "tg13", protocol : "TCP", port : var.APP_OUTGOING_PORTS[13], healthcheck : { port : var.APP_OUTGOING_PORTS[13], path : "", matcher : "" } },  # Chat EjabberD Service
    { index : 13, name : "tg14", protocol : "TCP", port : var.APP_OUTGOING_PORTS[14], healthcheck : { port : var.APP_OUTGOING_PORTS[14], path : "", matcher : "" } },  # Chat EjabberD HTTP
    { index : 14, name : "tg15", protocol : "TCP", port : var.APP_OUTGOING_PORTS[15], healthcheck : { port : var.APP_OUTGOING_PORTS[15], path : "", matcher : "" } },  # Chat Cantaloupe Service
    { index : 15, name : "tg16", protocol : "TCP", port : var.APP_OUTGOING_PORTS[16], healthcheck : { port : var.APP_OUTGOING_PORTS[16], path : "", matcher : "" } },  # Chat Cantaloupe Upload

  ]

  LISTENERS = [
    { target_index : 0, port_forward : var.APP_OUTGOING_PORTS[0], certificate_arn : null, protocol : "TCP" },
    { target_index : 1, port_forward : var.APP_OUTGOING_PORTS[1], certificate_arn : null, protocol : "TCP" },
    { target_index : 2, port_forward : var.APP_OUTGOING_PORTS[2], certificate_arn : null, protocol : "TCP" },
    { target_index : 3, port_forward : var.APP_OUTGOING_PORTS[3], certificate_arn : null, protocol : "TCP" },
    { target_index : 4, port_forward : var.APP_OUTGOING_PORTS[4], certificate_arn : null, protocol : "TCP" },
    { target_index : 5, port_forward : var.APP_OUTGOING_PORTS[5], certificate_arn : null, protocol : "TCP" },
    { target_index : 6, port_forward : var.APP_OUTGOING_PORTS[6], certificate_arn : null, protocol : "TCP" },
    { target_index : 7, port_forward : var.APP_OUTGOING_PORTS[7], certificate_arn : null, protocol : "TCP" },
    { target_index : 8, port_forward : var.APP_OUTGOING_PORTS[8], certificate_arn : null, protocol : "TCP" },
    { target_index : 9, port_forward : var.APP_OUTGOING_PORTS[10], certificate_arn : null, protocol : "TCP" },
    { target_index : 10, port_forward : var.APP_OUTGOING_PORTS[11],  certificate_arn : null, protocol : "TCP" },  # Chat EjabberD C2S
    { target_index : 11, port_forward : var.APP_OUTGOING_PORTS[12],  certificate_arn : null, protocol : "TCP" },  # Chat EjabberD HTTPS
    { target_index : 12, port_forward : var.APP_OUTGOING_PORTS[13],  certificate_arn : null, protocol : "TCP" },  # Chat EjabberD Service
    { target_index : 13, port_forward : var.APP_OUTGOING_PORTS[14],  certificate_arn : null, protocol : "TCP" },  # Chat EjabberD HTTP
    { target_index : 14, port_forward : var.APP_OUTGOING_PORTS[15],  certificate_arn : null, protocol : "TCP" },  # Chat Cantaloupe Service
    { target_index : 15, port_forward : var.APP_OUTGOING_PORTS[16],  certificate_arn : null, protocol : "TCP" },  # Chat Cantaloupe Upload

  ]

  NODE_GROUP_ASG_NAMES = [
    { target_index : 0, asg_group_name : module.asg_proxy.asg_name[0] },
    { target_index : 1, asg_group_name : module.asg_proxy.asg_name[0] },
    { target_index : 2, asg_group_name : module.asg_proxy.asg_name[0] },
    { target_index : 3, asg_group_name : module.asg_proxy.asg_name[0] },
    { target_index : 4, asg_group_name : module.asg_proxy.asg_name[0] },
    { target_index : 5, asg_group_name : module.asg_proxy.asg_name[0] },
    { target_index : 6, asg_group_name : module.asg_proxy.asg_name[0] },
    { target_index : 7, asg_group_name : module.asg_proxy.asg_name[0] },
    { target_index : 8, asg_group_name : module.asg_proxy.asg_name[0] },
    { target_index : 9, asg_group_name : module.asg_proxy.asg_name[0] },
    { target_index : 10, asg_group_name: module.asg_proxy.asg_name[0] },
    { target_index : 11, asg_group_name: module.asg_proxy.asg_name[0] },
    { target_index : 12, asg_group_name: module.asg_proxy.asg_name[0] },
    { target_index : 13, asg_group_name: module.asg_proxy.asg_name[0] },
    { target_index : 14, asg_group_name: module.asg_proxy.asg_name[0] },
    { target_index : 15, asg_group_name: module.asg_proxy.asg_name[0] },
  ]

  depends_on = [
    module.asg_proxy,
    module.eks
  ]
}

module "shared_efs" {
  source = "../modules/efs"

  NAME_PREFIX  = local.name_prefix
  DEFAULT_TAGS = local.common_tags

  TAG_NAME = "proxy"
  VPC_ID   = aws_vpc.vpc.id
  SUBNETS  = [aws_subnet.private_subnets[9].id, aws_subnet.private_subnets[10].id, aws_subnet.private_subnets[11].id]

  TRAFFIC_CIDRS_ALLOWED = [
    { "type" : "ingress", "cidr" : [var.PRIVATE_SUBNETS[9].cidr, var.PRIVATE_SUBNETS[10].cidr, var.PRIVATE_SUBNETS[11].cidr], "port" : 2049, "description" : "Proxy access to EFS" }
  ]
  #SECURITY_GROUPS = [ odumle.ec2_proxies.security_group ]
}

module "shared_efs_eks" {
  source = "../modules/efs"

  NAME_PREFIX     = local.name_prefix
  DEFAULT_TAGS    = local.common_tags

  TAG_NAME        = "eks"
  VPC_ID          = aws_vpc.vpc.id
  SUBNETS         = [aws_subnet.private_subnets[0].id, aws_subnet.private_subnets[1].id, aws_subnet.private_subnets[2].id]

  TRAFFIC_CIDRS_ALLOWED = [
    { "type" : "ingress", "cidr" : [var.PRIVATE_SUBNETS[0].cidr, var.PRIVATE_SUBNETS[1].cidr, var.PRIVATE_SUBNETS[2].cidr], "port" : 2049, "description" : "EKS access to EFS" }
  ]
}


module "eks" {
  source = "../modules/eks/"

  NAME_PREFIX  = local.name_prefix
  DEFAULT_TAGS = local.common_tags

  PUB_SUBNETS      = aws_subnet.public_subnets[*].id
  PVT_SUBNETS      = [aws_subnet.private_subnets[0].id, aws_subnet.private_subnets[1].id, aws_subnet.private_subnets[2].id]
  PVT_SUBNET_CIDRS = var.PRIVATE_SUBNETS[*].cidr
  VPC_ID           = aws_vpc.vpc.id
  VPC_CIDR         = var.VPC_CIDR_BLOCK

  NG_CAPACITY_TYPE = ["ON_DEMAND", "SPOT"]

  SPOT_DESIRED_SIZE = 9
  SPOT_MAX_SIZE     = 10
  SPOT_MIN_SIZE     = 1

  ON_DEMAND_DESIRED_SIZE = 8
  ON_DEMAND_MAX_SIZE     = 10
  ON_DEMAND_MIN_SIZE     = 2


  INSTANCE_DEFINITIONS = var.eks_instance_definitions
  WIT_CIDRS            = var.WIT_CIDRS

  AUTHORIZED_CIDRS_WN = [
    { type : "egress", cidrs : var.PRIVATE_SUBNETS[*].cidr, from_port : 0, to_port : 65535, protocol : "-1", description : "Allow cluster Nodes to communicate with entire VPC" },
    { type : "egress", cidrs : ["0.0.0.0/0"], from_port : 80, to_port : 80, protocol : "tcp", description : "SSM Access" },
    { type : "egress", cidrs : ["0.0.0.0/0"], from_port : 443, to_port : 443, protocol : "tcp", description : "SSM Access" },
    { type : "egress", cidrs : ["0.0.0.0/0"], from_port : 456, to_port : 456, protocol : "tcp", description : "Allow cluster Nodes communicates with SMTP (465) server" },
    { type : "egress", cidrs : ["0.0.0.0/0"], from_port : 587, to_port : 587, protocol : "tcp", description : "Allow cluster Nodes communicates with SMTP (587) server" },
    { type : "egress", cidrs : ["0.0.0.0/0"], from_port : 9100, to_port : 9100, protocol : "tcp", description : "Allow cluster Nodes send out prometheus metrics" },

    { type : "ingress", cidrs : [var.VPC_CIDR_BLOCK], from_port : 30080, to_port : 30080, protocol : "tcp", description : "Allow http traffic from elb to egress" },
    { type : "ingress", cidrs : [var.VPC_CIDR_BLOCK], from_port : 30081, to_port : 30081, protocol : "tcp", description : "Allow http traffic from elb to argocd" },
    { type : "ingress", cidrs : [var.VPC_CIDR_BLOCK], from_port : 30082, to_port : 30082, protocol : "tcp", description : "Allow http traffic from elb to grafana" },
    { type : "ingress", cidrs : [var.VPC_CIDR_BLOCK], from_port : 53, to_port : 53, protocol : "udp", description : "Allow DNS UDP traffic" },
  ]

  AUTHORIZED_CIDRS_CP = [
    { type : "egress", cidrs : [aws_subnet.private_subnets[0].cidr_block, aws_subnet.private_subnets[1].cidr_block, aws_subnet.private_subnets[2].cidr_block], from_port : 0, to_port : 0, protocol : "-1", description : "Allow cluster API Server to communicate with the worker nodes" },         # For SSM Access
    { type : "ingress", cidrs : [aws_subnet.private_subnets[0].cidr_block, aws_subnet.private_subnets[1].cidr_block, aws_subnet.private_subnets[2].cidr_block], from_port : 0, to_port : 0, protocol : "-1", description : "Allow cluster API Server to receive communications from worker nodes" }, # For SSM Access
  ]

  ARGOCD_CONFIG = {
    "install" : false,
    "username" : jsondecode(data.aws_secretsmanager_secret_version.data_argocd_sm.secret_string)["user"],
    "init_pass" : bcrypt(jsondecode(data.aws_secretsmanager_secret_version.data_argocd_sm.secret_string)["pass"])
    "repository" : "k8s"
  }

  NGINX_CONFIG = {
    "install" : true,
    "ingressName" : "${local.name_prefix}-nginx-ingress-controller",
    "lbName" : "vgsl-mps-mpesa-superapp-dev-eu-west-1-ingress-controller-svc",
    "lbType" : "nlb"
  }

  MONITOR_CONFIG = {
    "install" : true,
    "repository" : "https://prometheus-community.github.io/helm-charts",
    "chart" : "kube-prometheus-stack",
    "values_file" : "kube-prometheus-stack-values.yaml",
    # Custom Values
    "grafanaInitPassword" : jsondecode(data.aws_secretsmanager_secret_version.data_argocd_sm.secret_string)["pass"],
    "alertmanagerSlackApiUrl" : "https://hooks.slack.com/services/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",
    "alertmanagerSlackChannel" : "#bot-eth-alerts"
  }
  EFS_PROVISIONER = { 
    "install"  : true,
  }

  AUTH_MAP_ACCOUNT = var.auth_map_accounts
  VENDOR_ROLE      = "DevOps4"
}

module "eks_alb" {
  source = "../modules/loadbalancer_asg/"

  NAME_PREFIX  = local.name_prefix
  DEFAULT_TAGS = local.common_tags
  IDENTIFIER   = "${var.ProjectName}-${var.ENV}-eks-alb"

  TYPE        = "application"
  ACCESS_TYPE = "private"

  VPC_ID   = aws_vpc.vpc.id
  VPC_CIDR = var.VPC_CIDR_BLOCK
  SUBNETS  = { "private" : [aws_subnet.private_subnets[0].id, aws_subnet.private_subnets[1].id, aws_subnet.private_subnets[2].id], "public" : [] }
  NODE_GROUP_ASG_NAMES = [
    { "target_index" : 0, "asg_group_name" : module.eks.node_group_names[0] },
    { "target_index" : 0, "asg_group_name" : module.eks.node_group_names[1] }
  ]

  LOGGING_BUCKET_NAME   = "eks-nlb-logs"
  ACCESS_LOGS_BUCKET_ID = module.s3iam.access_logs_bucket_id

  TRAFFIC_CIDRS_ALLOWED = [
    { "type" : "ingress", "cidr" : ["0.0.0.0/0"], "port" : 80, "origin_sg_id" : null }, #HTTP
    #{ "type" : "ingress", "cidr" : ["0.0.0.0/0"], "from_port" : 443, "to_port" : 443, "origin_sg_id" : "null" } #HTTPS
    { type : "egress", cidr : ["0.0.0.0/0"], port : 80, "origin_sg_id" : null },
    { type : "egress", cidr : ["0.0.0.0/0"], port : 30080, "origin_sg_id" : null }
  ]

  TARGETS = [
    { index : 0, name : "tg-1", protocol : "HTTP", port : 30080, healthcheck : { path : "/", port : 30080, matcher : "200-499" } } #,
    #{ "index" : 0, "name" : "tg-2", "protocol" : "HTTP", "port" : 80, "healthcheck" : { "path" : null, "port" : 80 } }#,
    #{ "index" : 1, "name" : "tg-2", "protocol" : "HTTPS", "port" : 443, "healthcheck" : { "path" : null, "port" : 443 } }
  ]

  LISTENERS = [
    { "target_index" : 0, "port_forward" : 80, "certificate_arn" : null, "protocol" : "HTTP" } #, 
    #{ "target_index" : 1, "port_forward" : 443, "certificate_arn" : null, "protocol" : "HTTPS" }
  ]


  #TRAFFIC_CIDRS_ALLOWED = [vpc_link_values]
  depends_on = [
    module.eks
  ]
}


module "apigw" {
  source = "../modules/apigw/"

  NAME_PREFIX  = local.name_prefix
  DEFAULT_TAGS = local.common_tags

  VPC_ID          = aws_vpc.vpc.id
  PUB_SUBNETS     = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]
  PVT_SUBNETS     = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id, aws_subnet.public_subnets[2].id]
  SECURITY_GROUPS = [module.eks_alb.default_lb_sg[0]]
  #lb_listener_arn = module.eks.helm_release.nginx_ingress_controller.values
  LB_LISTENER_ARN = module.eks_alb.aws_lb_listeners_arns[0]
  API_STAGE_NAME  = var.ENV

  CUSTOM_DOMAIN_NAMES = [
    { "domain" : var.CUSTOM_DOMAIN_NAMES[0], "certificate_arn" : var.CUSTOM_DOMAIN_NAMES_CERTS[0] },
    { "domain" : var.CUSTOM_DOMAIN_NAMES[1], "certificate_arn" : var.CUSTOM_DOMAIN_NAMES_CERTS[1] },
    { "domain" : var.CUSTOM_DOMAIN_NAMES[2], "certificate_arn" : var.CUSTOM_DOMAIN_NAMES_CERTS[2] },
    { "domain" : var.CUSTOM_DOMAIN_NAMES[3], "certificate_arn" : var.CUSTOM_DOMAIN_NAMES_CERTS[3] }
  ]

  TRAFFIC_CIDRS_ALLOWED = [
    { "type" : "ingress", "cidr" : ["0.0.0.0/0"], "from_port" : 80, "to_port" : 80, "origin_sg_id" : "null" },                            #HTTP
    { "type" : "ingress", "cidr" : ["0.0.0.0/0"], "from_port" : 443, "to_port" : 443, "origin_sg_id" : "null" },                          #HTTPS
    { "type" : "egress", "cidr" : aws_subnet.private_subnets[*].cidr_block, "from_port" : 0, "to_port" : 65535, "origin_sg_id" : "null" } #,
    #{ "type" : "egress", "cidr" : aws_subnet.private_subnets[1], "from_port" : 0, "to_port" : 65535, "origin_sg_id" : "null" },
    #{ "type" : "egress", "cidr" : aws_subnet.private_subnets[2], "from_port" : 0, "to_port" : 65535, "origin_sg_id" : "null"}#,
    #{ "type" : "egress", "cidr" : [""], "from_port" : 80, "to_port" : 80, "origin_sg_id" : module.eks.eks_lb_default_sg_id },
  ]

  depends_on = [
    module.eks,
    module.eks_alb
  ]
}

module "docdb" {
  source = "../modules/docdb/"

  NAME_PREFIX  = local.name_prefix
  DEFAULT_TAGS = local.common_tags

  USERNAME = jsondecode(data.aws_secretsmanager_secret_version.data_docdb_db_sm.secret_string)["username"]
  PASSWORD = jsondecode(data.aws_secretsmanager_secret_version.data_docdb_db_sm.secret_string)["password"]

  VPC_ID      = aws_vpc.vpc.id
  PVT_SUBNETS = [aws_subnet.private_subnets[4].id, aws_subnet.private_subnets[5].id]

  IDENTIFIER   = var.DOCDB_IDENTIFIER
  NODES_NUMBER = 1

  TRAFFIC_CIDRS_ALLOWED = [
    { "type" : "ingress", "cidr" : aws_subnet.private_subnets[*].cidr_block, "port" : var.MONGO_PORT }, # Docdb in
    { "type" : "ingress", "cidr" : var.WIT_CIDRS, "port" : var.MONGO_PORT },                            # Docdb in
    #{ "type" : "ingress", "cidr" : ["${module.bastion.private_ip[0]}/32"], "port" : var.MONGO_PORT } # Bastion
  ]
}
module "rds_postgres" {
  source = "../modules/rds/"

  NAME_PREFIX  = local.name_prefix
  DEFAULT_TAGS = local.common_tags

  USERNAME = jsondecode(data.aws_secretsmanager_secret_version.data_rds_db_sm.secret_string)["username"]
  PASSWORD = jsondecode(data.aws_secretsmanager_secret_version.data_rds_db_sm.secret_string)["password"]

  VPC_ID      = aws_vpc.vpc.id
  PVT_SUBNETS = [aws_subnet.private_subnets[4].id, aws_subnet.private_subnets[5].id]

  IDENTIFIER    = var.RDS_IDENTIFIER
  DNS_ASSOCIATE = { "zone_id" : "${data.aws_route53_zone.dns_pvt.zone_id}", "name" : "rds" }
  ENGINE        = var.RDS_ENGINE_NAME
  DB_VERSION    = var.RDS_ENGINE_VERSION
  PARAM_GROUP   = var.RDS_PARAM_GROUP
  PORT_ACCESS   = var.RDS_PORT_ACCESS

  AUTO_TURN_OFF = var.RDS_AUTO_TURN_OFF
  DB_START_TIME = var.RDS_DB_START_TIME
  DB_STOP_TIME  = var.RDS_DB_STOP_TIME

  TRAFFIC_CIDRS_ALLOWED = [
    { "type" : "ingress", "cidr" : aws_subnet.private_subnets[*].cidr_block, "port" : var.RDS_PORT_ACCESS } #, # Postgres in
    #{ "type" : "ingress", "cidr" : ["${module.bastion.private_ip[0]}/32"],      "port" : var.RDS_PORT_ACCESS } # Bastion
  ]
}

module "s3iam" {
  source = "../modules/s3iam/"

  name_prefix       = local.name_prefix
  default_tags      = local.common_tags
  s3_logging_bucket = "s3-access-logs-mpesa-531477563173-logs"

}
