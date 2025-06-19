variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "EKS cluster certificate authority data"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "EKS cluster OIDC issuer URL"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "install_metrics_server" {
  description = "Whether to install metrics server"
  type        = bool
  default     = true
}

variable "install_cluster_autoscaler" {
  description = "Whether to install cluster autoscaler"
  type        = bool
  default     = true
}

variable "install_load_balancer_controller" {
  description = "Whether to install AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "install_argocd" {
  description = "Whether to install ArgoCD"
  type        = bool
  default     = false
}

variable "metrics_server_version" {
  description = "Version of metrics server to install"
  type        = string
  default     = "3.11.0"
}

variable "cluster_autoscaler_version" {
  description = "Version of cluster autoscaler to install"
  type        = string
  default     = "9.29.0"
}

variable "load_balancer_controller_version" {
  description = "Version of AWS Load Balancer Controller to install"
  type        = string
  default     = "1.6.2"
}

variable "load_balancer_controller_policy_version" {
  description = "Version of AWS Load Balancer Controller policy"
  type        = string
  default     = "v2.7.2"
}

variable "argocd_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "5.51.6"
}

variable "namespaces" {
  description = "List of namespaces to create"
  type = list(object({
    name        = string
    labels      = optional(map(string), {})
    annotations = optional(map(string), {})
  }))
  default = []
}

variable "argocd_namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_admin_password" {
  description = "Initial admin password for ArgoCD (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cluster_autoscaler_config" {
  description = "Cluster autoscaler configuration"
  type = object({
    scale_down_delay_after_add       = optional(string, "10m")
    scale_down_unneeded_time         = optional(string, "10m")
    scale_down_utilization_threshold = optional(string, "0.5")
    skip_nodes_with_local_storage    = optional(bool, true)
    skip_nodes_with_system_pods      = optional(bool, true)
  })
  default = {}
}

variable "metrics_server_config" {
  description = "Metrics server configuration"
  type = object({
    kubelet_insecure_tls            = optional(bool, true)
    kubelet_preferred_address_types = optional(list(string), ["InternalIP"])
  })
  default = {}
}

variable "argocd_config" {
  description = "ArgoCD configuration"
  type = object({
    server_service_type           = optional(string, "ClusterIP")
    enable_metrics              = optional(bool, true)
    ha_enabled                  = optional(bool, false)
    enable_notifications        = optional(bool, false)
    enable_applicationset       = optional(bool, true)
    create_app_of_apps         = optional(bool, false)
  })
  default = {
    server_service_type           = "ClusterIP"
    enable_ingress               = false
    ingress_host                 = ""
    ingress_class               = "alb"
    enable_tls                  = false
    enable_metrics              = true
    ha_enabled                  = false
    enable_notifications        = false
    enable_applicationset       = true
    create_app_of_apps         = false
    acm_certificate_arn         = ""
    alb_scheme                  = "internet-facing"
    alb_subnets                 = []
    alb_security_groups         = []
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_irsa" {
  description = "Whether to create OIDC provider for IRSA (set to false if already exists)"
  type        = bool
  default     = true
}
