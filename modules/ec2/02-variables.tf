locals {
  logging_bucket_name = "mpesa-${data.aws_caller_identity.current.account_id}-logs"
}

variable "DEFAULT_TAGS" {
  type = map(string)
  #default= {}
}

variable "NAME_PREFIX" {
  description = "Name of the module deployment to prefix all resource names with"
  default     = ""
}

variable "VPC_ID" {
  description = "VPC ID"
  default = ""
}

variable "VPC_CIDR" {
  description = "VPC CIDR Block"
}

variable "TYPE" {
  type = string
  default = "EC2"
}

variable "SUBNET_LIST" {
  description = "List of subnets into which the EC2 instances will be launched"
}

variable "INSTANCE_PROFILE" {
  description = "EC2 Instance profile name"
  default     = ""
}

variable "EC2_INSTANCE_ROLE" {
  description = "EC2 Instance profile role"
  default     = ""
}

variable "AWS_IAM_POLICIES"{
  description = "AWS-managed policies to add to instance profile"
  default     = []
}

variable "CUSTOM_IAM_POLICIES"{
  description = "Cutom IAM policy to add to instance profile"
  default     = []
}

variable "CREATE_INSTANCE_PROFILE" {
  description = "EC2 Instance profile name"
  type        = bool
  default     = false
}

variable "INSTANCE_FUNCTION" {
  description = "Purpose of the EC2 - if equals BASTION -> SG rule for bastion"
  type = string
  default = ""
}

variable "INSTANCE_DEFINITIONS" {
  type = object({
    ami              = string
    instance_type    = string
    root_volume_size = number
    subnet           = string
    index            = number 
    hostnum          = number 
  })
  description = "Self managed EC2 Instances configurations - outside of clusters"
}

variable "IAM_INSTANCE_PROFILE_NAME" {
  description = "Name of the iam nstance profile to attach to ec2"
  default     = ""
}

variable "TAG_NAME" {
  description = "Tag name of instance"
  default     = ""
  type        = string 
}

variable "CREATE_EIP" {
  description = "Bool value to indicate weather an EIP is to be created or not for the instance"
  type        = bool
  default     = false
}

variable "AUTHORIZED_EC2_CIDRS" {
  description = "List of CIDRs which have access to or from the EC2 instance"
  type        = list(object({
    type        = string
    cidr        = list(string)
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))

  default = []
}

variable "AUTHORIZED_EC2_SG" {
  description = "List of Security Group IDs which have access to or from the EC2 instance"
  type        = list(object({
    type              = string
    security_group_id = string
    from_port         = number
    to_port           = number
    protocol          = string
    description       = string
  }))

  default = []
}

variable "TREND_PLAN" {
  description = "Trendmicro default plan"
  default = "min"
}

variable "ASG_USERDATA_FILENAME"{
  description = "Filename to use for instance userdata"
  type        = string
  default     = "default-asg-userdata.tpl"
}

variable "EC2_USERDATA_FILENAME"{
  description = "Filename to use for ASG userdata"
  type        = string
  default     = "default-ec2-userdata.tpl"
}

variable "CUSTOM_USERDATA_FILENAME"{
  description = "Filename to use for EFS userdata"
  type        = string
  default     = ""
}

variable "ASSOCIATE_PUBLIC_IP" {
  description = "If it is necessary to associate a public IP address to an instance"
  type        = bool
  default     = false
}

variable "EBS_SIZE" {
  description = "Size for root EBS for instances (both EC2 and ASG)"
  type        = number
  default     = 20
}

variable "EFS_DNS" {
  description = "EFS DNS name"
  type        = string
  default     = ""
}

variable "EFS_MOUNT_PATH" {
  description = "Path to mount EFS"
  type        = string
  default     = "/efs-mount-path"
}

variable "EFS_SECURITY_GROUP" {
  description = "EFS SG to add rule for EC2 SG"
  default     = null
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
variable "AUTO_TURN_OFF" {
  description = "Whether or not to automatically start and stop instances"
  default     = "No"
}

variable "VENDOR_ROLE" {
  description = "Default vendor role for instances"
  default     = ""
  type        = string 
}

variable "ASG_DESIRED" {
  description = "Desired ASG nodes"
  type        = number
  default     = 2
}

variable "ASG_MAX" {
  description = "Maximum ASG nodes"
  type        = number
  default     = 3
}

variable "ASG_MIN" {
  description = "Minimum ASG nodes"
  type        = number
  default     = 1
}

variable "ASG_FORCE_DELETE" {
  description = "ASG Force delete settings"
  type        = bool
  default     = false
}

variable "ASG_HEALTH_CHECK" {
  description = "ASG Health Check path"
  type        = string
  default     = "EC2"
}

variable "ASG_LIFECYCLE" {
  description = "Lifecycle of the ASGG nodes"
  type        = string
  default     = "ON DEMAND"
}

variable "UPDATE_ASG" {
  description = "value"
  type        = bool
  default     = false
}