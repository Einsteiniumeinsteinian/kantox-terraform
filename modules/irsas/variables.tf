# terraform/modules/irsa/variables.tf

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

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL"
  type        = string
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs"
  type        = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "main_api_repo_name" {
  description = "Main API repository name"
  type        = string
}

variable "auxiliary_service_repo_name" {
  description = "Auxiliary service repository name"
  type        = string
}

variable "account_id" {
  description = "The AWS account ID of the caller"
  type        = string
}
