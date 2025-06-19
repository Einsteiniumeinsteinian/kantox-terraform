# terraform/modules/s3/variables.tf
variable "general_tags" {
  description = "Global required tags for all resources"
  type = object({
    Environment = string
    Owner       = string
    Project     = string
    Team        = string
    ManagedBy   = optional(string, "terraform")
  })
}

variable "buckets" {
  description = "S3 buckets configuration"
  type = map(object({
    versioning = bool
    encryption = bool
  }))
}

variable "name_prefix" {
  description = "Prefix for security group names"
  type        = string
  default     = ""
}

variable "name_suffix" {
  description = "Suffix for security group names"
  type        = string
  default     = ""
}
