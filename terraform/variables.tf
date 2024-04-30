#######################
## Generic Variables ##
#######################

variable "default_tags" {
  type = map(string)
  default= {}
}

variable "ENV" {
  description = "Environment in which to perform changes"
  default     = ""
}

variable "deploy_role" {
  type = string
  description = "Role for deployment"
}
  
variable "ENV_NAME" {
 description = "Environent Name"
 default = ""
}

variable "ENVTAG" {
  description = "Environment Tag Name"
  default = ""
}

variable "ProjectName" {
  description = "Project name primarily used for DLM"
  default = ""
}

variable "Market" {
  description = "Name of Market"
  default = ""
}

variable "ReleaseTrain" {
  description = "ReleaseTrain Tag value"
  default = ""
}

variable "ManagedBy" {
  description = "ManagedBy email environment"
  default = ""
}

variable "WIT_CIDRS"{
  description = "List of WIT CIDRs which are allowed to communicate with Bastion Host"
  type        = list(string) 
}

#######################
## RABBIT Variables ###
#######################

variable "RABBIT_TAG_NAME" {
  description = "Tag name for RabbitMQ Instances"
  type        = string
  default     = "comms-rabbit"
}

variable "EC2_TYPE" {
  type        = string
  default     = "EC2"
}

variable "ASG_TYPE"{
  type        = string
  default     = "ASG"
}

###################
## VPC variables ##
###################

### VPC Peering Related ###
variable "VPC_PEER_SETTINGS_SFCNONPRODSS" {
  description = "Settings to apply to vpc peering"

  type = object({
    PEER_VPC_CIDR_BLOCK = string
    PEER_ACCOUNT_ID     = string
    PEER_VPC_ID         = string
    PEER_AZ             = string
    PEER_REGION         = string
  })
  default = {
    PEER_ACCOUNT_ID     = ""
    PEER_VPC_ID         = ""
    PEER_VPC_CIDR_BLOCK = ""
    PEER_AZ             = ""
    PEER_REGION         = ""
  }
}

### VPC Peering Related ###
variable "VPC_PEER_SETTINGS_SHARED_SERVICES" {
  description = "Settings to apply to vpc peering"

  type = object({
    PEER_VPC_CIDR_BLOCK = string
    PEER_ACCOUNT_ID     = string
    PEER_VPC_ID         = string
    PEER_AZ             = string
    PEER_REGION         = string
  })
  default = {
    PEER_ACCOUNT_ID     = ""
    PEER_VPC_ID         = ""
    PEER_VPC_CIDR_BLOCK = ""
    PEER_AZ             = ""
    PEER_REGION         = ""
  }
}

### VPC Related ###
variable "VPC_CIDR_BLOCK" {
  type = string
  description = "VPC CIDR Block"
}
variable "vpc_order" {
  description = "VPC number order (sufix name)"
  default     = "01"
}

### Subnet Related ###

variable "PRIVATE_SUBNETS" {
  description = "Private Subnet CIDR Blocks"
  type          = list(object({
    az          = string
    cidr        = string
    description = string
  })) 
}

variable "PUBLIC_SUBNETS" {
  description = "Public Subnet CIDR Blocks"
  type          = list(object({
    az          = string
    cidr        = string
    description = string
  })) 
}

variable "vpc_route_pvt_tables" {
  type = list(string)
  description = "List Of private route tables"
  default     = [""]
}

variable "NAT_GW_COUNT" { #?
  description = "Number of NAT Gateways to include in the infrastructure"
  type        = number
  default     = 2
}

###

variable "vpc_public_cidr_blocks" { #?
  description = "List of CIDR blocks which can access the Amazon EKS private API server endpoint, when public access is disabled"
  type        = number
  default     = 2
}

variable "vpc_private_cidr_blocks" { #?
  description = "List of CIDR blocks which can access the Amazon EKS private API server endpoint, when public access is disabled"
  type        = number
  default     = 2
}

variable "TrendMicroSvcName" { #?
  description = "Name for TrendMicroService"
  default     = ""
}

variable "TrendMicroDNS" { #?
  description = "Name for TrendMicroDNS"
  default     = "aws-shared.vodafone.com"
}

variable "TrendMicroDSMRecordName" { #?
  description = "Name for TrendMicroDSMRecordName"
  default     = "trend-dsm.aws-shared.vodafone.com"
}

variable "TrendMicroSPSRecordName" { #?
  description = "Name for TrendMicroSPSRecordName"
  default     = "trend-sps.aws-shared.vodafone.com"
}

variable "DNSNAME" {
  description = "DNS Name"
  default     = "placeholder"
}

variable "CHAT_DNSNAME_ZONE" {
  description = "DNS Name for Smartapp Chat Hosted Zone"
}

variable "BUSINESSSERVICE" {
  description = "Business service name"
  default     = ""
}

#######################
# EC2 & ASG Variables #
#######################

variable "default_ec2_definition" {
 type = object({
      ami                 = string
      instance_type       = string
      root_volume_size    = number
      subnet              = string
      index               = number
      hostnum             = number
 })
}

variable "instance_function" {
  description = "The purpose of the EC2 instance"
  type        = string
  default     = "BASTION"
}

variable "ASG_DESIRED" {
  description = "value"
  type        = number
  default     = 2
}

variable "ASG_MAX" {
  description = "value"
  type        = number
  default     = 3
}

variable "ASG_MIN" {
  description = "value"
  type        = number
  default     = 1
}

variable "ASG_FORCE_DELETE" {
  description = "value"
  type        = bool
  default     = false
}

variable "ASG_HEALTH_CHECK" {
  description = "value"
  type        = string
  default     = "EC2"
}

variable "UPDATE_ASG" {
  description = "value"
  type        = bool
  default     = true
}

#######################
#### EKS Variables ####
#######################

variable "auth_map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)

  default = [
    "531477563173",
    "556361159589",
  ]
}

variable "eks_instance_definitions" {
 type = map(object({
      ami                 = string
      instance_type       = string
      root_volume_size    = number
      subnet              = string
      index               = number
      hostnum             = number
 }))
}

variable "ARGOCD_SECRET_ARN" {
  description = "Secret ARN of ArgoCD Access"
  default     = ""
}

#######################
#### RDS Variables ####
#######################

variable "RDS_ENGINE_NAME" {
  description = "DataBase Type of RDS Instance"
  default     = ""
}

variable "RDS_IDENTIFIER" {
  description = "Database identifier to use for the RDS Database"
}


variable "RDS_ENGINE_VERSION" {
  description = "Engine version to use for the RDS Database"
}

variable "RDS_PARAM_GROUP" {
  description = "Parameter group family for the RDS Database"
}

variable "RDS_INSTANCE_TYPE" {
  description = "Instance type to use for the RDS Database"
}

variable "RDS_STORAGE_TYPE" {
  description = "Storage type to use for the RDS Database (in GB)"
  default     = ""
}

variable "RDS_STORAGE_SIZE" {
  description = "Storage size to use for the RDS Database (in GB)"
  default     = ""
}

variable "RDS_PORT_ACCESS" {
  description = "Port to use for the RDS Database"
}

variable "RDS_SECRET_ARN" {
  description = "Secret ARN of RDS DB Access"
  default     = ""
}

variable "RDS_DB_START_TIME" {
  description = "Start time of the DB Instances"
  default     = ""
}

variable "RDS_DB_STOP_TIME" {
  description = "Stop time of the DB Instances"
  default     = ""
}
variable "RDS_AUTO_TURN_OFF" {
  description = "Whether or not to automatically start and stop instances"
  default     = "No"
}

#######################
### DocDB Variables ###
#######################

variable "DOCDB_IDENTIFIER" {
  description = "DocumentDB Identifier Cluster and Instance"
  default     = ""
}

variable "DOCDB_SECRET_ARN" {
  description = "Secret ARN of DOC DB Access"
  default     = ""
}

variable "MONGO_PORT" {
 description = "Postgres default port"
 default     = ""
}

#######################
### APIGW Variables ###
#######################

variable "NGINX_LB_LISTENER80_ARN" {
 description = "NGINX Loadbalancer Port 80 Listener ARN"
 type        = string
 default     = ""
}

variable "NGINX_LB_LISTENER443_ARN" {
 description = "NGINX Loadbalancer APort 443 Listene RN"
 type        = string
 default     = ""
}

variable "CUSTOM_DOMAIN_NAMES" {
  type        = list(string)
  description = "Apigateway custom domain names"
}

variable "CUSTOM_DOMAIN_NAMES_CERTS" {
  type        = list(string)
  description = "Apigateway custom domain names certificates"
}

#######################
##### LB Variables ####
#######################

variable "NLB_NAME" {
  description = "custom name due to char limits"
  type        = string
  default     = ""
}

#######################
#### Port Variables ###
#######################

variable "APP_OUTGOING_PORTS" {
  description = "App security outgoing ports"
}

variable "APP_OUTGOING_PORTS_DESC" {
  description = "App security outgoing ports description "
}

variable "VDF_INTEGRATION_INCOMING_PORTS" {
  description = "App security inbound integration ports"
  default     = ""
}

variable "VDF_INTEGRATION_INCOMING_PORTS_DESC" {
  description = "App security inbound integration ports description "
  default     = ""
}

variable "VDF_INTEGRATION_OUTGOING_PORTS" {
  description = "App security outgoing integration ports"
  default     = ""
}

variable "VDF_INTEGRATION_OUTGOING_PORTS_DESC" {
  description = "App security outgoing integration ports description "
  default     = ""
}

variable "VDF_VDFSVC_OUTGOING_IP" {
  description = "App security outgoing integration ips for VDF services"
  default     = ""
}
variable "VDF_VDFSVC_OUTGOING_PORTS" {
  description = "App security outgoing integration ports for VDF services"
  default     = ""
}

variable "VDF_VDFSVC_OUTGOING_PORTS_DESC" {
  description = "App security outgoing integration ports description for VDF services"
  default     = ""
}

variable "VPNPROXY_IP" {
  description = "VPN Proxy IP"
}

variable "POSTGRES_PORT" {
 description = "Postgres default port"
 default = ""
}

variable "HZ_PORT" {
 description = "Hazelcast default port"
 default = ""
}


variable "RABBIT_PORT" {
 description = "Hazelcast default port"
 default = ""
}

variable "RABBIT_EPMD_PORT" {
 description = "Hazelcast EPMD Connect port"
 default = ""
}

variable "rule_schedule" {
  description = "A CRON expression specifying when AWS Backup initiates a backup job"
  type        = string
  default     = null
}

variable "rule_start_window" {
  description = "The amount of time in minutes before beginning a backup"
  type        = number
  default     = 60
}

variable "rule_completion_window" {
  description = "The amount of time AWS Backup attempts a backup before canceling the job and returning an error"
  type        = number
  default     = 120
}

# Rule lifecycle
variable "rule_lifecycle_cold_storage_after" {
  description = "Specifies the number of days after creation that a recovery point is moved to cold storage"
  type        = number
  default     = 30
}

variable "rule_lifecycle_delete_after" {
  description = "Specifies the number of days after creation that a recovery point is deleted. Must be 90 days greater than `cold_storage_after`"
  type        = number
  default     = 120
}


variable "selection_tag_type" {
  description = "An operation, such as StringEquals, that is applied to a key-value pair used to filter resources in a selection"
  type        = string
  default     = "STRINGEQUALS"
}

variable "selection_tag_key" {
  description = "The key in a key-value pair"
  type        = string
  default     = "Backup"
}

variable "selection_tag_value" {
  description = "The value in a key-value pair"
  type        = string
  default     = "false"
}

variable "enable_continuous_backup" {
  description = "The value to enable_continuous_backup"
  type        = string
  default     = "false"
}

variable "retention_period" {
  description = "The value to retention period"
  type        = string
  default     = "2"
}