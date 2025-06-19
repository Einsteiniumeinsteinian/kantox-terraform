# variables.tf

variable "network" {
  description = "network properties"
  type = object({
    cidr_block        = string
    Azs               = list(string)
    private_subnet    = list(string)
    public_subnet     = list(string)
    create_default_sg = bool
  })
}

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

variable "optional_tags" {
  description = "Optional tags per resource type"
  type = object({
    vpc     = optional(map(string), {})
    public_subnets = optional(map(string), {})
    private_subnets = optional(map(string), {})
    internet_gateway = optional(map(string), {})
  })
  default = {}
}

variable "name_prefix" {
  description = "Optional name prefix for all resource Name tags"
  type        = string
  default     = ""
}

variable "name_suffix" {
  description = "Optional name suffix for all resource Name tags"
  type        = string
  default     = ""
}
