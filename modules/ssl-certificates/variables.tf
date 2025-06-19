# modules/ssl-certificates/variables.tf

variable "domain_name" {
  description = "Primary domain name for the certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names for the certificate"
  type        = list(string)
  default     = []
}

variable "certificate_name" {
  description = "Name for the certificate (used in tags)"
  type        = string
}

variable "auto_validate" {
  description = "Whether to automatically validate the certificate (requires DNS records to be added externally)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the certificate"
  type        = map(string)
  default     = {}
}