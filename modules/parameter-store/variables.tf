# terraform/modules/parameter-store/variables.tf
variable "parameters" {
  description = "Parameters to store in AWS Parameter Store"
  type = map(object({
    type        = string
    value       = string
    description = string
  }))
}

variable "general_tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}