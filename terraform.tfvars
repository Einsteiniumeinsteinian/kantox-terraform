# =============================================================================
# General
# =============================================================================
general_tags = {
  Environment = "staging"
  Owner       = "chibuzo"
  Project     = "infra"
  Team        = "devops"
  ManagedBy   = "terraform"

}

name_prefix = "ab1"
name_suffix = ""
aws_region  = "us-west-2"

# =============================================================================
# VPC
# =============================================================================

network = {
  cidr_block        = "10.0.0.0/16"
  Azs               = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnet    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  create_default_sg = true
}

# =============================================================================
# SECURITY GROUP
# =============================================================================

security_group_config = {
  create_security_groups   = true
  create_ingress_rules     = false
  create_egress_rules      = false
  enable_default_egress    = false
  existing_security_groups = {}

  security_groups = [
    {
      name        = "jump-server"
      description = "Security group for Jump Server"
    },
    {
      name        = "eks-cluster"
      description = "Security group for EKS cluster"
    },
    {
      name        = "eks-node-group"
      description = "Security group for EKS node groups"
    },
    {
      name        = "nlb"
      description = "Security group for Network Load Balancer"
    }
  ]
}

security_group_config_rules = {
  create_security_groups = false
  create_ingress_rules   = true
  create_egress_rules    = true
  enable_default_egress  = false
}

# Office/Admin CIDR blocks
office_cidr_blocks = ["0.0.0.0/0"] # Replace with your actual office IP ranges

# VPC CIDR block
vpc_cidr_block = "10.0.0.0/16"

# Port configurations (if you want to make them configurable)
standard_ports = {
  ssh   = 22
  http  = 80
  https = 443
}

# High port range for EKS
eks_high_port_range = {
  from = 1025
  to   = 65535
}

# =============================================================================
# EKS Cluster
# =============================================================================

cluster = {
  name                     = "app-eks"
  version                  = "1.32"
  enable_encryption        = true
  kms_key_deletion_window  = 7
  enable_cluster_log_types = ["api", "audit"]
  log_retention_in_days    = 7
  endpoint_private_access  = true
  endpoint_public_access   = true
  public_access_cidrs      = ["0.0.0.0/0"]
}

cluster_network = {
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["0.0.0.0/0"]
}

eks_node_groups_config = {
  node_groups = {
    spot = {
      desired_capacity = 0
      max_capacity     = 5
      min_capacity     = 0
      instance_types = [
        "t3.medium", "t3.large", "t3.xlarge",
        "t3a.medium", "t3a.large", "t3a.xlarge",
        "m5.large", "m5.xlarge",
        "m5a.large", "m5a.xlarge",
        "m4.large", "m4.xlarge"
      ],
      capacity_type = "SPOT"
      disk_size     = 30
      disk_type     = "gp3"
      k8s_labels = {
        "node.kubernetes.io/lifecycle"     = "spot"
        "node.kubernetes.io/capacity-type" = "spot"
      }
      k8s_taints = [
        {
          key    = "node.kubernetes.io/capacity-type"
          value  = "spot"
          effect = "NO_SCHEDULE"
        }
      ]
      max_unavailable_percentage = 50
    }

    on-demand = {
      desired_capacity = 2
      max_capacity     = 4
      min_capacity     = 2
      instance_types   = ["t3.medium"]
      capacity_type    = "ON_DEMAND"
      disk_size        = 20
      disk_type        = "gp3"
      k8s_labels = {
        "node.kubernetes.io/lifecycle"     = "on-demand"
        "node.kubernetes.io/capacity-type" = "on-demand"
      }
    }
  }

  settings = {
    enable_monitoring = true
    enable_imdsv2     = true
    name_prefix       = ""
    name_suffix       = ""
  }
}


eks_addons = [
  {
    name                        = "vpc-cni"
    resolve_conflicts_on_update = "OVERWRITE"

  },
  {
    name                        = "kube-proxy"
    resolve_conflicts_on_update = "OVERWRITE"

  },
  {
    name                        = "coredns"
    resolve_conflicts_on_update = "OVERWRITE"
  },
  {
    name                        = "aws-ebs-csi-driver"
    resolve_conflicts_on_update = "OVERWRITE"
  }
]

# ───────────────────────────────────────
# ECR Settings
# ───────────────────────────────────────

ecr_repositories = [
  {
    name                 = "auxiliary-service"
    scan_on_push         = true
    image_tag_mutability = "MUTABLE"
    lifecycle_policy_rules = [
      {
        rulePriority  = 1
        description   = "Keep last 10 images"
        tagStatus     = "tagged"
        tagPrefixList = ["v"]
        countType     = "imageCountMoreThan"
        countNumber   = 10
        action_type   = "expire"
      }
    ]
  },
  {
    name                 = "main-api"
    scan_on_push         = true
    image_tag_mutability = "MUTABLE"
    lifecycle_policy_rules = [
      {
        rulePriority  = 1
        description   = "Keep last 10 images"
        tagStatus     = "tagged"
        tagPrefixList = ["v"]
        countType     = "imageCountMoreThan"
        countNumber   = 10
        action_type   = "expire"
      }
    ]
  }
]

# ───────────────────────────────────────
# PARAMETERS
# ───────────────────────────────────────

parameters = {
  "app/database/host" = {
    type        = "String"
    value       = "localhost"
    description = "Database host"
  }
  "app/api/version" = {
    type        = "String"
    value       = "1.0.0"
    description = "API version"
  }
  "app/features/debug" = {
    type        = "String"
    value       = "true"
    description = "Debug mode flag"
  }
}

# ───────────────────────────────────────
# S3
# ───────────────────────────────────────
s3_buckets = {
  "app-data" = {
    versioning = true
    encryption = true
  }
  "app-logs" = {
    versioning = false
    encryption = true
  }
}

# ───────────────────────────────────────
# CERTIFICATES
# ───────────────────────────────────────

auto_validate_certificates = true

irsa_config = {
  github_org                  = "Einsteiniumeinsteinian"
  main_api_repo_name          = "Kantox-main-api"
  auxiliary_service_repo_name = "Kantox-auxiliary-service"
}

ssl_certificate = {
  domain_name = "kantox.api.einsteiniumeinsteinian.cloud"
  subject_alternative_names = [
    "*.einsteiniumeinsteinian.cloud",
    "einsteiniumeinsteinian.cloud"
  ]
}

certificate_settings = {
  auto_validate = false
}

# ───────────────────────────────────────
# KUBERNETES RESOURCES
# ───────────────────────────────────────

k8s_resources_config = {
  install_metrics_server           = true
  install_cluster_autoscaler       = true
  install_load_balancer_controller = true
  install_argocd                   = true
  enable_irsa                      = true

  # ArgoCD Configuration
  argocd_namespace      = "argocd"
  argocd_version        = "5.51.6"
  argocd_admin_password = "MySecurePassword123!" # Use AWS Secrets Manager in production

  # ArgoCD with ALB Ingress
  argocd_config = {
    # Features
    enable_metrics        = true
    enable_applicationset = true
    enable_notifications  = false

    # Single replica (non-HA)
    ha_enabled = false
  }

  # Component configurations
  metrics_server_config = {
    kubelet_insecure_tls            = true
    kubelet_preferred_address_types = ["InternalIP", "ExternalIP", "Hostname"]
  }

  cluster_autoscaler_config = {
    scale_down_delay_after_add       = "10m"
    scale_down_unneeded_time         = "10m"
    scale_down_utilization_threshold = "0.5"
    skip_nodes_with_local_storage    = true
    skip_nodes_with_system_pods      = true
  }
}
# Namespaces configuration
namespaces = [
  {
    name = "main-api"
    labels = {
      "role"        = "primary"
      "environment" = "staging"
      "name"        = "main-api"
    }
    annotations = {
      "description" = "Main application namespace"
    }
    metadata = {
      "name" = "main-api"
    }
  },
  {
    name = "auxiliary-service"
    labels = {
      "role"        = "secondary"
      "environment" = "staging"
    }
    annotations = {
      "description" = "Auxiliary services"
    }
  },
  {
    name = "monitoring"
    labels = {
      "role"        = "secondary"
      "environment" = "staging"
    }
    annotations = {
      "description" = "Monitoring services"
    }
  },
  {
    name = "argocd"
    labels = {
      "argocd.argoproj.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"     = "argocd"
      name                            = "argocd"

    }
    annotations = {
      "description" = "ArgoCD namespace for GitOps"
    }
  }
]

