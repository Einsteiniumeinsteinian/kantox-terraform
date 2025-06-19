# variables.tf

# =============================================================================
# General
# =============================================================================

variable "general_tags" {
  description = "Required base tags for all resources"
  type = object({
    Environment = string
    Owner       = string
    Project     = string
    Team        = string
    ManagedBy   = optional(string, "terraform")
  })
}

variable "optional_tags" {
  description = "Optional resource-specific tags"
  type = object({
    vpc             = optional(map(string), {})
    public_subnets  = optional(map(string), {})
    private_subnets = optional(map(string), {})
  })
  default = {}
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
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

# =============================================================================
# VPC
# =============================================================================

variable "network" {
  description = "Network configuration for VPC, subnets, etc."
  type = object({
    cidr_block        = string
    Azs               = list(string)
    private_subnet    = list(string)
    public_subnet     = list(string)
    create_default_sg = bool
  })
}

# =============================================================================
# SECURITY GROUP
# =============================================================================

variable "security_group_config" {
  description = "Configuration for managing security groups"
  type = object({
    create_security_groups = optional(bool, true)
    create_ingress_rules   = optional(bool, true)
    create_egress_rules    = optional(bool, true)
    enable_default_egress  = optional(bool, false)
    security_groups = list(object({
      name        = string
      description = string
      ingress_rules = optional(list(object({
        from_port                = number
        to_port                  = number
        protocol                 = string
        cidr_blocks              = optional(list(string))
        ipv6_cidr_blocks         = optional(list(string))
        source_security_group_id = optional(string)
        self                     = optional(bool, false)
        description              = string
      })), [])
      egress_rules = optional(list(object({
        from_port                = number
        to_port                  = number
        protocol                 = string
        cidr_blocks              = optional(list(string))
        ipv6_cidr_blocks         = optional(list(string))
        source_security_group_id = optional(string)
        self                     = optional(bool, false)
        description              = string
      })), [])
    }))
  })
}

variable "security_group_config_rules" {
  description = "Configuration for managing security groups"
  type = object({
    create_security_groups = optional(bool, true)
    create_ingress_rules   = optional(bool, true)
    create_egress_rules    = optional(bool, true)
    enable_default_egress  = optional(bool, false)
  })
}

variable "office_cidr_blocks" {
  description = "CIDR blocks for office/admin access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Should be restricted to actual office IPs
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "standard_ports" {
  description = "Standard port definitions"
  type = object({
    ssh   = number
    http  = number
    https = number
  })
  default = {
    ssh   = 22
    http  = 80
    https = 443
  }
}

variable "eks_high_port_range" {
  description = "High port range for EKS communication"
  type = object({
    from = number
    to   = number
  })
  default = {
    from = 1025
    to   = 65535
  }
}

# =============================================================================
# EKS Cluster
# =============================================================================

variable "cluster" {
  description = "Cluster configuration values"
  type = object({
    name                     = string
    version                  = string
    enable_encryption        = bool
    enable_cluster_log_types = list(string)
    log_retention_in_days    = number
    kms_key_deletion_window  = number
  })
}

variable "cluster_network" {
  description = "Network-related configuration"
  type = object({
    endpoint_private_access = bool
    endpoint_public_access  = bool
    public_access_cidrs     = list(string)
  })
}

variable "eks_addons" {
  description = "List of EKS add-ons to deploy"
  type = list(object({
    name                        = string
    configuration_values        = optional(string)
    preserve                    = optional(bool)
    service_account_role_arn    = optional(string)
    resolve_conflicts_on_update = optional(string)
  }))
}

variable "eks_node_groups_config" {
  description = "Grouped config for EKS node groups"
  type = object({
    node_groups = map(object({
      desired_capacity = number
      max_capacity     = number
      min_capacity     = number
      instance_types   = list(string)
      capacity_type    = string
      disk_size        = number
      disk_type        = string
      k8s_labels       = map(string)
      k8s_taints = optional(list(object({
        key    = string
        value  = string
        effect = string
      })), [])
      max_unavailable_percentage    = optional(number)
      additional_security_group_ids = optional(list(string), [])
      subnet_ids                    = optional(list(string))
    }))
    settings = object({
      enable_monitoring = bool
      enable_imdsv2     = bool
      name_prefix       = string
      name_suffix       = string
    })
  })
}

# ───────────────────────────────────────
# ECR Settings
# ───────────────────────────────────────

variable "ecr_repositories" {
  description = "List of ECR repositories with lifecycle policies"
  type = list(object({
    name                 = string
    scan_on_push         = bool
    image_tag_mutability = string
    lifecycle_policy_rules = list(object({
      rulePriority  = number
      description   = string
      tagStatus     = string
      tagPrefixList = list(string)
      countType     = string
      countNumber   = number
      action_type   = string
    }))
  }))
}

# ───────────────────────────────────────
# PARAMETERS
# ───────────────────────────────────────

variable "parameters" {
  description = "Parameters to store in AWS Parameter Store"
  type = map(object({
    type        = string
    value       = string
    description = string
  }))
}

# ───────────────────────────────────────
# S3
# ───────────────────────────────────────
variable "s3_buckets" {
  description = "S3 buckets to create"
  type = map(object({
    versioning = bool
    encryption = bool
  }))
}

# ───────────────────────────────────────
# CERTIFICATES
# ───────────────────────────────────────
variable "auto_validate_certificates" {
  description = "Automatically validate certificates (set to false for manual DNS setup)"
  type        = bool
  default     = false
}

variable "irsa_config" {
  description = "Configuration for IRSA (IAM Roles for Service Accounts)"
  type = object({
    github_org                  = string
    main_api_repo_name          = string
    auxiliary_service_repo_name = string
  })
}

variable "ssl_certificate" {
  description = "SSL certificate configuration"
  type = object({
    domain_name               = string
    subject_alternative_names = list(string)
  })
}

variable "certificate_settings" {
  description = "Global certificate settings"
  type = object({
    auto_validate = bool
  })
  default = {
    auto_validate = true
  }
}

# ───────────────────────────────────────
# k8s_resources_config
# ───────────────────────────────────────

variable "k8s_resources_config" {
  description = "Configuration for K8s resources"
  type = object({
    # Component installation flags
    install_metrics_server           = optional(bool, true)
    install_cluster_autoscaler       = optional(bool, true)
    install_load_balancer_controller = optional(bool, true)
    install_argocd                   = optional(bool, false)
    enable_irsa                      = optional(bool, true)

    # ArgoCD configuration
    argocd_namespace      = optional(string, "argocd")
    argocd_version        = optional(string, "5.51.6")
    argocd_admin_password = optional(string, "")

    # Component configurations
    metrics_server_config = optional(object({
      kubelet_insecure_tls            = optional(bool, true)
      kubelet_preferred_address_types = optional(list(string), ["InternalIP"])
    }), {})

    cluster_autoscaler_config = optional(object({
      scale_down_delay_after_add       = optional(string, "10m")
      scale_down_unneeded_time         = optional(string, "10m")
      scale_down_utilization_threshold = optional(string, "0.5")
      skip_nodes_with_local_storage    = optional(bool, true)
      skip_nodes_with_system_pods      = optional(bool, true)
    }), {})

    argocd_config = optional(object({
      server_service_type   = optional(string, "ClusterIP")
      enable_metrics        = optional(bool, true)
      ha_enabled            = optional(bool, false)
      enable_notifications  = optional(bool, false)
      enable_applicationset = optional(bool, true)
      create_app_of_apps    = optional(bool, false)
    }), {})
  })
  default = {}
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
