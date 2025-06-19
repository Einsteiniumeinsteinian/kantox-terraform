# modules/eks-addons/variables.tf

variable "addons" {
  description = "List of EKS add-ons to install"
  type = list(object({
    name                      = string
    configuration_values      = optional(string)
    preserve                  = optional(bool)
    service_account_role_arn  = optional(string)
    resolve_conflicts_on_update = optional(string)
  }))
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "general_tags" {
  description = "Map of general tags to apply to all resources"
  type        = map(string)
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
