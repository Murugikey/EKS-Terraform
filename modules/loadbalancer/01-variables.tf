variable "LOGGING_BUCKET_NAME" {
  type = string
  default = ""
}
variable "ACCESS_LOGS_BUCKET_ID" {
  type = string
  default = "S3 Logs Buckets"
}
variable "DEFAULT_TAGS" {
  type = map(string)
  default = {}
}
variable "NAME_PREFIX" {
  description = "Name of the module deployment to prefix all resource names with"
  default = ""
}
variable "IDENTIFIER" {
  description = "Name of this Load Balancer"
  default = ""
}
variable "TYPE" {
  description = "Type of AWS ELB"
  default = "network"
}
variable "VPC_ID" {
  description = "VPC ID"
  type = string
  default = ""
}
variable "VPC_CIDR" {
  description = "VPC CIDR"
  type = string
  default = ""
}
variable "ACCESS_TYPE" {
  description = "Type of LB Access (private or public)"
  type        = string
  default     = "private"
}
variable "SUBNETS" {
  description = "Object List of CIDR blocks of Subnets (Public and Private)"
  type        = object({
    public  = list(any)
    private = list(any)
  })

  default = {
    private = []
    public = []
  }
}

variable "DELETION_PROTECTION" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "OUTBOUND_SECURITY_GROUPS" {
  description = "List of security groups to add to outbound traffic for default SG"
  type        = list(object({
    id    = string
    fromPort  = number
    toPort  = number
  }))
  default     = []
}

variable "INBOUND_SECURITY_GROUPS" {
  description = "List of security groups to add to allow indbound traffic for default SG"
  type        = list(object({
    id    = string
    fromPort  = number
    toPort  = number
  }))
  default     = []
}

variable "TARGETS" {
  description = "A list of targets requests"
  type        = list(object({
    index       = number
    name        = string
    port        = number
    protocol    = string
    healthcheck = object({
      path    = string
      port    = number
      matcher = string
    })
  }))

  default = [ {
    healthcheck = {
      path    = "value"
      port    = 1
      matcher = "value"
    }
    index = 1
    name = "value"
    port = 1
    protocol = "value"
  } ]
}

variable "LISTENERS" {
  description = "A list of listners from targets"
  type        = list(object({
    target_index     = number
    port_forward     = number
    certificate_arn  = string 
    protocol         = string
  }))

  default = [ {
    certificate_arn = "null"
    target_index = 0
    port_forward = 80
    protocol     = "TCP"
  } ]
}

variable "INSTANCES" {
  type = list(any)
  description = "List of Instances ids" 
  default = []
}
variable "NODE_GROUP_ASG_NAMES" {
  type = list(object({
    target_index = number
    asg_group_name = string
  }))
  description = "List of ASG group names attached to EKS Node Groups"
  default = []
}

variable "TRAFFIC_CIDRS_ALLOWED" {
  description = "List of CIDRs traffic is allowed (Ingress and Egress)"
  type = list(object({
    type = string
    cidr = list(string)
    port = number
  }))
  default = []
}