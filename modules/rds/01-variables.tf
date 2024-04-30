locals {
  ### Segregate definitions
  # Licenses
  licenses = {
    "postgres" = "postgresql-license"
    ## mysql, oracle, mariadb, [here] ...
  }

  # CloudWatch Logs Exports
  logs_exports = {
    "postgres" = ["postgresql"]
    ## mysql, oracle, mariadb, [here] ...
  }

  engine_current_version  = var.DB_VERSION
  license_current_version = lookup(local.licenses, var.ENGINE, "default")
  db_param_group_family   = var.PARAM_GROUP
  logs_exports_current    = lookup(local.logs_exports, var.ENGINE, "default")
}

variable "NAME_PREFIX" {
  description = "Name of the module deployment to prefix all resource names with"
  default     = ""
}

variable "DEFAULT_TAGS" {
  type    = map(string)
  default = {}
}

variable "ENGINE" {
  type        = string
  description = "DataBase Language Type"
  default     = "postgres"

  validation {
    condition     = contains(["postgres"], var.ENGINE)
    error_message = "Just 'postgres' can able at moment."
  }
}
variable "DB_VERSION" {
  type        = string
  description = "Version of Engine"
  default     = "postgres14"

  # validation {
  #   condition     = contains(["14.1", "12.10"], var.DB_VERSION)
  #   error_message = "Just 'postgres14' and 'postgres12' can able at moment."
  # }
}
variable "PARAM_GROUP" {
  type        = string
  description = "Version of Engine"
  default     = "14.1"

  validation {
    condition     = contains(["postgres14", "postgres12"], var.PARAM_GROUP)
    error_message = "Just '14.1' and '12.10' can able at moment."
  }
}

variable "VPC_ID" {
  description = "Id of VPC"
  default = ""
}

variable "IDENTIFIER" {
  type        = string
  description = "RDS Indentifier name"
  
  validation {
    condition     = can(regex("^[0-9a-z-]+$", var.IDENTIFIER))
    error_message = "For the 'IDENTIFIER' value only a-z (lowercase) and 0-9 are allowed."
  }
}

variable "DNS_ASSOCIATE" {
  type        = object({
    zone_id    = string
    name       = string
  })
  
  description = "Address to be set as a Route 35 record and config to RDS DNS Name created by AWS. If dns_associate.name null is passed, nothing happens"
}

variable "USERNAME" {
  type        = string
  description = "RDS Master Username"
}

variable "PASSWORD" {
  type        = string
  description = "RDS Master Password"
}

variable "ALLOCATED_STORAGE" {
  type        = number
  description = "Storage space"
  default     = 50
}

variable "STORAGE_TYPE" {
  type        = string
  description = "Type of storage space"
  default     = "gp2"
}

variable "MULTI_AZ" {
  type        = bool
  default     = false
}

variable "INSTANCE_CLASS" {
  type        = string
  default     = "db.t3.micro" 
}

variable "PORT_ACCESS" {
  type        = number
  description = "DataBase port access"
}

variable "RETENTION_PERIOD" {
  type        = number
  default     = 2
}

variable "PVT_SUBNETS" {
  type        = list(string)
  description = "List of IDs of Private SubNet for RDS DB Subnet Group"
}


variable "TRAFFIC_CIDRS_ALLOWED" {
  description = "List of CIDRs traffic is allowed (Ingress and Egress)"
  type        = list(object({
    type = string
    cidr = list(string)
    port = number
  }))

  
}

### AUTO START AND STOP DB INSTANCES ###
variable "DB_START_TIME" {
  description = "Start time of the DB Instances"
  default     = ""
}

variable "DB_STOP_TIME" {
  description = "Stop time of the DB Instances"
  default     = ""
}
variable "AUTO_TURN_OFF" {
  description = "Whether or not to automatically start and stop instances"
  default     = "No"
}