# variables.tf

variable "vpc_id" {
  description = "VPC ID where security groups will be created (required when creating new security groups)"
  type        = string
  default     = null
}

variable "create_security_groups" {
  description = "Whether to create new security groups"
  type        = bool
  default     = true
}

variable "existing_security_groups" {
  description = "Map of existing security group IDs to attach rules to (used when create_security_groups = false)"
  type        = map(string)
  default     = {}
}

variable "security_groups" {
  description = "List of security groups to create or configure"
  type = list(object({
    name        = string
    description = string
    ingress_rules = optional(list(object({
      from_port                = number
      to_port                  = number
      protocol                 = string
      cidr_blocks             = optional(list(string))
      ipv6_cidr_blocks        = optional(list(string))
      source_security_group_id = optional(string)
      self                    = optional(bool, false)
      description             = string
    })), [])
    egress_rules = optional(list(object({
      from_port                = number
      to_port                  = number
      protocol                 = string
      cidr_blocks             = optional(list(string))
      ipv6_cidr_blocks        = optional(list(string))
      source_security_group_id = optional(string)
      self                    = optional(bool, false)
      description             = string
    })), [])
  }))
  
  validation {
    condition     = length(var.security_groups) > 0
    error_message = "At least one security group must be defined."
  }
  
  validation {
    condition = alltrue([
      for sg in var.security_groups : 
      length(sg.name) > 0 && length(sg.description) > 0
    ])
    error_message = "Security group name and description cannot be empty."
  }
}

variable "create_ingress_rules" {
  description = "Whether to create ingress rules"
  type        = bool
  default     = true
}

variable "create_egress_rules" {
  description = "Whether to create egress rules"
  type        = bool
  default     = true
}

variable "general_tags" {
  description = "Required base tags (must include Project and Environment)"
  type = object({
    Environment = string
    Owner       = string
    Project     = string
    Team        = string
    ManagedBy   = optional(string, "terraform")
  })
}

variable "name_prefix" {
  description = "Optional name prefix"
  type        = string
  default     = ""
}

variable "name_suffix" {
  description = "Optional name suffix"
  type        = string
  default     = ""
}

variable "enable_default_egress" {
  description = "Whether to keep the default egress rule (allow all outbound traffic)"
  type        = bool
  default     = false
}

variable "optional_tags" {
  description = "Optional tags per resource type"
  type = object({
    security_groups= optional(map(string), {})
  })
  default = {}
}
