# modules/eks-cluster/variables.tf
variable "cluster" {
  description = "Cluster configuration values"
  type = object({
    name                      = string
    version                   = string
    enable_encryption         = bool
    enable_cluster_log_types = list(string)
    log_retention_in_days     = number
    kms_key_deletion_window   = number
  })
}

variable "network" {
  description = "Network-related configuration"
  type = object({
    vpc_id                     = string
    subnet_ids                 = list(string)
    endpoint_private_access    = bool
    endpoint_public_access     = bool
    public_access_cidrs        = list(string)
    security_groups_ids = list(string)
  })
}


variable "general_tags" {
  description = "General tags including Environment and Project"
  type = object({
    Environment = string
    Owner       = string
    Project     = string
    Team        = string
    ManagedBy   = optional(string, "terraform")
  })
}

variable "name_prefix" {
  description = "Optional prefix for all name tags"
  type        = string
  default     = ""
}

variable "name_suffix" {
  description = "Optional suffix for all name tags"
  type        = string
  default     = ""
}

variable "optional_tags" {
  description = "Optional tags per resource type"
  type = object({
    launch_template = optional(map(string), {})
  })
  default = {}
}