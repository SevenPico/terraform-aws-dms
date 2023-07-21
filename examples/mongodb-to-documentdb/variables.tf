
variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
}

variable "mongodb_user" {
  type        = string
  description = "Username for the master DB user"
}

variable "mongodb_password" {
  type        = string
  description = "Password for the master DB user"
}

variable "mongodb_database_name" {
  type = string
}
variable "mongodb_server" {
  type = string
}

variable "mongodb_port" {
  type        = number
  description = "Database port"
}

variable "create_dms_iam_roles" {
  type        = bool
  description = "Flag to enable/disable the provisioning of the required DMS IAM roles. The roles should be provisioned only once per account. See https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Security.html for more details"
  default     = true
}


variable "ddb_port" {
  type = number
}

variable "vpc_cidr_block" {
  type = string
}

variable "root_domain" {
  type = string
}
