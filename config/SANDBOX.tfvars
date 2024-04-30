##########################
### GENERAL
##########################

#RUN_STARTUP_SCRIPTS = "true"

#DEPLOY_ROLE = "arn:aws:iam::556361159589:role/mpesa-superapp-sandbox-cicd-codebuild-role-yxvu"

ENVTAG          = "Sandbox"
ENV             = "Sandbox"
BUSINESSSERVICE = "Credrail-Test"
DNSNAME         = "eks.dev.credrail.com"
ReleaseTrain    = "Digital"
Market          = "ETH"
ProjectName     = "Credrails"
ManagedBy       = "vcredrails"

VPC_CIDR_BLOCK = "10.51.0.0/16"


PUBLIC_SUBNETS = [ 
    // INDEX: 0
    { 
        az          = 0, # Public #1 AZ0
        cidr        = "10.51.194.64/26"
        description = "Public-Subnet-1"
    }, 
    // INDEX: 1
    {
        az          = 1, # Public #2 AZ1
        cidr        = "10.51.194.128/26"
        description = "Public-Subnet-2"
    },
    // INDEX: 2
    {
        az          = 2, # Public #3 AZ2
        cidr        = "10.51.194.192/26"
        description = "Public-Subnet-3"
    },
    // INDEX: 3
    {
        az          = 0, # Firewall #1 AZ0
        cidr        = "10.51.195.0/26"
        description = "Firewall-Subnet-1"
    },
    // INDEX: 4 
    {
        az          = 1, # Firewall #2 AZ1
        cidr        = "10.51.195.64/26"
        description = "Firewall-Subnet-2"
    },
    // INDEX: 5
    {
        az          = 2, # Bastion #3 AZ2
        cidr        = "10.51.195.128/26"
        description = "Firewall-Subnet-3"
    },
]

PRIVATE_SUBNETS = [
    // INDEX: 0 
    { 
        az          = 0, 
        cidr        = "10.51.0.0/18"
        description = "EKS-Subnet-1"
    }, 
     // INDEX: 1
    {
        az          = 1, 
        cidr        = "10.51.64.0/18"
        description = "EKS-Subnet-2"
    },
     // INDEX: 2
    {
        az          = 2, 
        cidr        = "10.51.128.0/18"
        description = "EKS-Subnet-3"
    }, 
    // INDEX: 3
    {
        az          = 0, 
        cidr        = "10.51.192.0/26"
        description = "Comms-Layer-Subnet-1"
    }, 
    // INDEX: 4
    {
        az          = 1, 
        cidr        = "10.51.192.64/26"
        description = "Comms-Layer-Subnet-2"
    },  
    // INDEX: 5
    {
        az          = 2, 
        cidr        = "10.51.192.128/26"
        description = "Comms-Layer-Subnet-3"
    },
    // INDEX: 6
    {
        az          = 0,
        cidr        = "10.51.192.192/26"
        description = "DB-Subnet-1"
    }, 
    // INDEX: 7
    {
        az          = 1,
        cidr        = "10.51.193.0/26"
        description = "DB-Subnet-2"
    },  
    // INDEX: 8
    {
        az          = 2, 
        cidr        = "10.51.193.64/26"
        description = "DB-Subnet-3"
    },
    // INDEX: 9
    {
        az          = 0, 
        cidr        = "10.51.193.128/26"
        description = "Proxy-Subnet-1"
    }, 
    // INDEX: 10
    {
        az          = 1,  
        cidr        = "10.51.193.192/26"
        description = "Proxy-Subnet-2"
    },
    // INDEX: 11
    {
        az          = 2, 
        cidr        = "10.51.194.0/26"
        description = "Proxy-Subnet-3"
    }
]

vpc_route_pvt_tables = [ "rt1", "rt2" ]

##### AMIs #####

#cloudbees_cd_ami = "ami-0cf4e9db215e806d8" #7.7 rhel

TrendMicroSvcName = "vpce-svc-021ea81a4876d04a1"

default_ec2_definition = {
    ami              = "ami-0c18b526d255a74c7"
    instance_type    = "t3a.xlarge"
    root_volume_size = 20
    subnet           = "private"
    index            = 0
    hostnum          = 5
}

eks_instance_definitions = {
    "eks_bastion_host" : {
    ami              = "ami-0c18b526d255a74c7"
    instance_type    = "t3a.micro"
    root_volume_size = 20
    subnet           = "private"
    index            = 0
    hostnum          = 5
  },
  "spot_worker_nodes" : {
    ami              = "ami-0c227b57bb33f3ef5"
    instance_type    = "t3a.xlarge"
    root_volume_size = 20
    subnet           = "private"
    index            = 0
    hostnum          = 5
  },
  "on_demand_worker_nodes" : {
    ami              = "ami-0c227b57bb33f3ef5"
    instance_type    = "t3a.xlarge"
    root_volume_size = 20
    subnet           = "private"
    index            = 0
    hostnum          = 5
  },
  "proxy" : {
    ami              = "ami-000f1512f78b5d1bc"
    instance_type    = "t3a.small"
    root_volume_size = 50
    subnet           = "private"
    index            = 0
    hostnum          = 3
  }
}

# For DLM purpose
#RDS_APP_START_TIME = "0700"
#RDS_APP_STOP_TIME  = "2330"
RDS_AUTO_TURN_OFF  = "Yes"
RDS_DB_START_TIME  = "0700"
RDS_DB_STOP_TIME   = "2330"

#ASG_DESIRED      = 
#ASG_MAX          =   
#ASG_MIN          =   
#ASG_FORCE_DELETE =
#ASG_HEALTH_CHECK =
#UPDATE_ASG       = true


####################################
#### DOC DB Instance - [MongoDB] ###
####################################
### DocumentDB ###
DOCDB_IDENTIFIER  = "vgsl-mps-mpesa-superapp-dev-docdb"
DOCDB_SECRET_ARN  = "arn:aws:secretsmanager:eu-west-1:531477563173:secret:vgsl-mps.mpesa-superapp-dev-eu-west-1-asm-docdb.01-5BwLPR"

#####################################
### RDS DB Instance - [Postgres] ####
#####################################

RDS_IDENTIFIER     = "vgsl-mps-mpesa-superapp-dev-rds"
RDS_ENGINE_NAME    = "postgres"
RDS_ENGINE_VERSION = "14.2" #commented to silence warnings
RDS_PARAM_GROUP    = "postgres14" #commented to silence warnings
RDS_STORAGE_TYPE   = "gp2" #commented to silence warnings
RDS_STORAGE_SIZE   = 30 #commented to silence warnings
RDS_PORT_ACCESS    = 5432 #commented to silence warnings
RDS_INSTANCE_TYPE  = "db.t3.micro"
RDS_SECRET_ARN     = "arn:aws:secretsmanager:eu-west-1:531477563173:secret:vgsl-mps.mpesa-superapp-dev-eu-west-1-asm-postgres.01-acDmP4"

MONGO_PORT         = "27017"

#####################################
########### API GW Domains ##########
#####################################

CUSTOM_DOMAIN_NAMES = [ "backoffice.superapp.m-pesa.com", "gateway.superapp.m-pesa.com" ]
CUSTOM_DOMAIN_NAMES_CERTS = [ "arn:aws:acm:eu-west-1:531477563173:certificate/418e41ba-0ef9-49cd-8f27-7c370d7eed3e", "arn:aws:acm:eu-west-1:531477563173:certificate/3464cebc-e0a8-44e8-bc7e-2f6c33cf0e45" ]

#####################################
#### Helm installed tools access ####
#####################################

### Argo CD ###
ARGOCD_SECRET_ARN = "arn:aws:secretsmanager:eu-west-1:531477563173:secret:vgsl-mps.mpesa-superapp-dev-eu-west-1-asm-argocd.01-77JoUu"

### NGINX Load Balancer ###
NGINX_LB_LISTENER80_ARN = "arn:aws:elasticloadbalancing:eu-west-1:531477563173:listener/net/a1c81c89bfe3e469ab936e0fa3ff5b0c/9990168047b6d669/51380ea444951cae"
NGINX_LB_LISTENER443_ARN = "arn:aws:elasticloadbalancing:eu-west-1:531477563173:listener/net/a1c81c89bfe3e469ab936e0fa3ff5b0c/9990168047b6d669/e868ae6bb4cd3b39"

#auth_map_roles = [
#  {
#    rolearn  = "arn:aws:iam::531477563173:role/SysAdmin"
#    username = "SysAdmin"
#    groups   = ["sysadmin-k8s-group"]
#  },
#   {
#    rolearn  = "arn:aws:iam::531477563173:role/-kubectl-role"
#    username = "mpesa-smartapp-kubectl-role"
#    groups   = ["system:masters"]
#  },
#  {
#    rolearn  = "arn:aws:iam::531477563173:role/mpesa-smartapp-eks-node-role"
#    username = "system:node:{{EC2PrivateDNSName}}"
#    groups   = ["system:masters"]
#  }
# ]
#
# 
#auth_map_accounts = ["531477563173", "556361159589"]
#
HZ_PORT            = 5701
RABBIT_PORT        = 5672
RABBIT_EPMD_PORT   = 4369
POSTGRES_PORT      = 5432
#
#APP_INCOMING_PORTS      = [8080, 8081]
#APP_INCOMING_PORTS_DESC = ["Gateway", "Backoffice"]
#
APP_OUTGOING_PORTS      = [
    587, 
    389, 
    8083, 
    8084, 
    8085, 
    8086, 
    8090, 
    8091
]
APP_OUTGOING_PORTS_DESC = [
    "SMTPS", 
    "LDAP", 
    "External services (hakikisha, statements, etc)", 
    "FCM",
    "G2", 
    "SSMP", 
    "JFrog",
    "Github"
]

VDF_INTEGRATION_OUTGOING_PORTS      = [26445, 8445, 26456, 26450]
VDF_INTEGRATION_OUTGOING_PORTS_DESC = ["DEV SMSC", "G2 DEV", "SMS2 DEV", "IPG DEV"]

VDF_VDFSVC_OUTGOING_IP         = ["34.244.209.123","34.244.209.123","34.243.248.59","34.243.248.59"]
VDF_VDFSVC_OUTGOING_PORTS      = [31888, 31998, 32032, 32060]
VDF_VDFSVC_OUTGOING_PORTS_DESC = ["HAKIKISHA UAT", "STATEMENTS UAT", "ERECEIPTS UAT", "REVERSALS UAT"]

VPNPROXY_IP = "99.81.37.84"

NLB_NAME               = "smp-superapp-et-dev-proxy-nlb" //custom name due to char limits
#NLB_HealthyHostCount   = "2"
#NLB_UnHealthyHostCount = "1"
#
#ARGO_NLB_NAME          = "argo-smartapp-et-dev-access"
#
#enable_remedy = "false"
#
#ALB_APP_CERTIFICATE = ""
#
#ALB_BO_CERTIFICATE = ""
#
#### Secrets
#RDS_DB_SECRET_ARN = ""
#
WIT_CIDRS = ["88.157.194.232/29", "88.157.218.160/27", "89.115.251.144/29", "88.157.219.208/29", "62.28.228.192/30", "62.48.198.4/30", "34.240.143.185/32"]
#WIT_CIDRS = [""]
#
#APIGW_GW_CERTIFICATE_ARN=""
#APIGW_BO_CERTIFICATE_ARN=""
#
### ECR Reposiotry names
#ECR_REPOSITORIES = {
#  "WIT_BASE_IMAGE" : "wit-image/wit-base-image"
#  "WIT_MS_JOBS" : "wit-ms-jobs/jobs"
#}