locals {
  logging_bucket_name = "mpesa-${data.aws_caller_identity.current.account_id}-logs"
}
variable "deploy_nwi_proxy" {
  description = "count of proxy enis to be created"
  type        = number
  default     = 1
}



variable "s3_logging_bucket" {
  description = "S3 Bucket to send access logs to, must be preconfigured"
  default     = "s3-access-logs-mpesa-531477563173-logs"
}

####### Variables for AMIs ########

 variable "name_prefix" {
   description = "For unique resource name"
   default = "mpesa-cps-"
 }

variable "default_tags" {
  type = map(string)
  #default= {}
}

### AUTO START AND STOP INSTANCES ###
variable "AppStartTime" {
  description = "Start time of the Application Instances"
  default     = ""
}

variable "AppStopTime" {
  description = "Stop time of the Application Instances"
  default     = ""
}
variable "AutoTurnOFF" {
  description = "Whether or not to automatically start and stop instances"
  default     = "No"
}

