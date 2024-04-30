locals {
  logging_bucket_name = "mpesa-${data.aws_caller_identity.current.account_id}-logs"
  eks_oidc_thumbprint = {
    "eu-west-1" = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280" 
  }
}

variable "DEFAULT_TAGS" {
  type = map(string)
  default = {}
}

variable "NAME_PREFIX" {
  description = "Name of the module deployment to prefix all resource names with"
  default = ""
}

variable "WIT_CIDRS"{
  description = "List of WIT CIDRs which are allowed to communicate with Bastion Host"
  type        = list(string) 
}

variable "AUTHORIZED_CIDRS_WN" {
  description = "List of CIDRs which that have access to or from the EC2 instance"
  type        = list(object({
    type        = string
    cidrs       = list(string)
    from_port   = number
    to_port     = number
    description = string
    protocol    = string
  }))

  default = []
}

variable "AUTHORIZED_CIDRS_CP" {
  description = "List of SG IDs which have access to or from the EC2 instance"
  type        = list(object({
    type        = string
    cidrs       = list(string)
    from_port   = number
    to_port     = number
    description = string
    protocol    = string
  }))

  default = []
}

variable "AUTHORIZED_SG_WN" {
  description = "List of SG IDs which have access to or from the Worker Nodes instance"
  type        = list(object({
    type              = string
    security_group_id = string
    from_port         = number
    to_port           = number
    description       = string
    protocol          = string
  }))

  default = []
}

variable "AUTHORIZED_SG_CP" {
  description = "List of SG IDs which have access to or from the Worker Nodes instance"
  type        = list(object({
    type              = string
    security_group_id = string
    from_port         = number
    to_port           = number
    description       = string
    protocol          = string
  }))

  default = []
}

variable "PUB_SUBNETS" {
  description = "List of CIDR blocks which can access the Amazon EKS private API server endpoint, when public access is disabled"
  type        = list(string)
  #default     = [""]
}

variable "PVT_SUBNETS" {
  description = "List of CIDR blocks which can access the Amazon EKS private API server endpoint, when public access is disabled"
  type        = list(string)
  #default     = [""]
}

variable "PVT_SUBNET_CIDRS" {
  description = "List of CIDR blocks which can access the Amazon EKS private API server endpoint, when public access is disabled"
  #default     = [""]
}

variable "SG_IDS" {
  description = "List of Security Group Ids to allow access around EKS Cluster"
  type        = list(string)
  default     = [""]
}

variable "CLUSTER_ORDER_NUMBER" {
  description = "EKS Cluster sequential order number"
  default = "01"
}

variable "K8S_VERSION" {
  description = "Kubernetes Version of Master Node"
  default = "1.23"
}

variable "NG_ORDER_NUMBER" {
  description = "Node Group sequential order number of EKS Cluster"
  default = "01"
}

variable "NG_CAPACITY_TYPE" {
  type        = list(string)
  description = "Capacity Type of EKS Cluster Node Group"
  default     = ["ON_DEMAND"]

  #validation {
  #  condition     =  contains(["ON_DEMAND", "SPOT"], var.ng_capacity_type)
  #  error_message = "Just 'ON_DEMAND' or 'SPOT' are available."
  #}
}

variable "INSTANCE_DEFINITIONS" {
  type = map(object({
    ami              = string
    instance_type    = string
    root_volume_size = number
    subnet           = string
    index            = number 
    hostnum          = number
  }))

  description = "WorkerNodes and BastionHost Instances (optional) configuration"
}

variable "ARGOCD_CONFIG" {
  type        = object({
    install    = bool
    username   = string        
    repository = string
    init_pass  = string
  })
  description = "Configures ArgoCD in Bastion Host on Start Script"
  default = {
    install    = false
    repository = null
    username   = null
    init_pass  = null
  }

  ### Issue around cross variables validation
  ### https://github.com/hashicorp/terraform/issues/25609
  # validation {
  #   condition     = var.argocd_config.install == false || contains(keys(INSTANCE_DEFINITIONS), "eks_bastion_host")
  #   error_message = "ArgoCD Configuration depends the Bastion Exists. Please check your 'INSTANCE_DEFINITIONS'."
  # }
}

variable "MONITOR_CONFIG" {
  type        = object({
    install     = bool
    repository  = string
    chart       = string
    values_file = string
    # Custom values
    grafanaInitPassword = string
    alertmanagerSlackApiUrl = string
    alertmanagerSlackChannel = string
  })
  description = "MONITOR Configuring"
}

variable "EFS_PROVISIONER" {
  type        = object({
    install   = bool
  })
}

variable "SPOT_DESIRED_SIZE" {
  description = "value for pvt desired size"
  default = 0
}
variable "SPOT_MAX_SIZE" {
  description = "value for pvt max size"
  default = 0
}
variable "SPOT_MIN_SIZE" {
  description = "value for pvt min size"
  default = 0
}

variable "AUTH_MAP_ACCOUNT" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)

  default = [
    "1111"
  ]
}

#######

variable "VPC_ID" {
  description = "Name of the module deployment to prefix all resource names with"
  default = ""
}

variable "VPC_CIDR" {
  default = ""
  description = "Name of the module deployment to prefix all resource names with"
}


variable "ON_DEMAND_DESIRED_SIZE" {
  description = "value for desired size"
  default = 0

}
variable "ON_DEMAND_MAX_SIZE" {
  description = "value for max size"
  default = 0

}
variable "ON_DEMAND_MIN_SIZE" {
  description = "value for min size"
  default = 0

}

variable "AUTH_MAP_ROLES" {
  description = "Additional IAM roles to add to the aws-auth configmap. See examples/basic/variables.tf for example format."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

### NGINX Variables ###

variable "NGINX_CONFIG" {
  description = "Configuration to use for NGINX Controller"
  type        = object({
    install     = bool
    ingressName = string
    lbType      = string        
    lbName      = string
  })

  default = {
    install     = false
    ingressName = ""
    lbType     = ""
    lbName     = ""
  }
}

### AUTO START AND STOP INSTANCES ###

variable "AUTO_TURN_OFF" {
  description = "Whether or not to automatically start and stop instances"
  default     = "No"
}

variable "AUTO_START_TIME" {
  description = "Start time of the Instances"
  default     = ""
}

variable "AUTO_STOP_TIME" {
  description = "Stop time of the Instances"
  default     = ""
}

variable "PVT_SUBNET_ENI" {
  description = "pvt_subnet_eni"
  default     = ""
}

variable "TREND_PLAN" {
  description = "Trendmicro default plan"
  default = "min"
}

### AUTO START AND STOP INSTANCES ###

variable "APP_START_TIME" {
  description = "Start time of the Application Instances"
  default     = ""
}

variable "APP_STOP_TIME" {
  description = "Stop time of the Application Instances"
  default     = ""
}

variable "VENDOR_ROLE" {
  description = "Default vendor role for instances"
  default     = ""
  type        = string 
}

variable "SPOT_INSTANCE_COUNTER" {
  description = "Counter for tagging instances"
  default     = [ 0 ]
  type        = list(number)
}

variable "ON_DEMAND_INSTANCE_COUNTER" {
  description = "Counter for tagging instances"
  default     = [ 0 ]
  type        = list(number)
}