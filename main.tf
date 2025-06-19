#######################################
#             LOCALS                 #
#######################################

locals {
  prefix_dash     = var.name_prefix != "" ? "${var.name_prefix}-" : ""
  suffix_dash     = var.name_suffix != "" ? "-${var.name_suffix}" : ""
  cluster_name    = "${local.prefix_dash}${var.general_tags.Environment}-${var.general_tags.Project}-${var.cluster.name}-cluster${local.suffix_dash}"
  cluster_tag_key = "kubernetes.io/cluster/${local.cluster_name}"
}



#######################################
#             DATASOURCE             #
#######################################

data "aws_caller_identity" "current" {}

#######################################
#             VPC MODULE             #
#######################################

module "vpc" {
  source = "./modules/vpc"

  general_tags = var.general_tags
  network      = var.network

  optional_tags = {
    vpc = {
      Purpose                    = "core-networking"
      "${local.cluster_tag_key}" = "owned"
    }

    public_subnets = {
      "kubernetes.io/role/elb"   = "1"
      "${local.cluster_tag_key}" = "owned"
    }

    private_subnets = {
      "kubernetes.io/role/internal-elb" = "1"
      "${local.cluster_tag_key}"        = "owned"
    }
  }
}

############################################
#     SECURITY GROUPS CREATION MODULE     #
############################################

module "security_groups" {
  source       = "./modules/security-groups"
  vpc_id       = module.vpc.vpc_id
  name_prefix  = var.name_prefix
  name_suffix  = var.name_suffix
  general_tags = var.general_tags

  create_security_groups = try(var.security_group_config.create_security_groups, true)
  create_ingress_rules   = try(var.security_group_config.create_ingress_rules, false)
  create_egress_rules    = try(var.security_group_config.create_egress_rules, false)
  enable_default_egress  = try(var.security_group_config.enable_default_egress, false)
  security_groups        = var.security_group_config.security_groups

  optional_tags = {
    security_groups = {
      "${local.cluster_tag_key}" = "owned"
    }
  }
}

####################################################
#    SECURITY GROUP RULES (USING EXISTING SGs)    #
####################################################

module "security_group" {
  source = "./modules/security-groups"

  create_security_groups = var.security_group_config_rules.create_security_groups
  create_ingress_rules   = var.security_group_config_rules.create_ingress_rules
  create_egress_rules    = var.security_group_config_rules.create_egress_rules

  existing_security_groups = {
    jump-server    = module.security_groups.security_group_ids["jump-server"]
    eks-cluster    = module.security_groups.security_group_ids["eks-cluster"]
    eks-node-group = module.security_groups.security_group_ids["eks-node-group"]
  }

  general_tags = var.general_tags

  security_groups = [
    {
      name        = "jump-server"
      description = "Rules for Jump Server"

      ingress_rules = [
        {
          from_port   = var.standard_ports.ssh
          to_port     = var.standard_ports.ssh
          protocol    = "tcp"
          cidr_blocks = var.office_cidr_blocks
          description = "SSH access from office"
        }
      ]

      egress_rules = [
        {
          from_port   = var.standard_ports.ssh
          to_port     = var.standard_ports.ssh
          protocol    = "tcp"
          cidr_blocks = [var.vpc_cidr_block]
          description = "SSH to private instances"
        },
        {
          from_port   = var.standard_ports.https
          to_port     = var.standard_ports.https
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS outbound"
        }
      ]
    },

    {
      name        = "eks-cluster"
      description = "Rules for EKS cluster"

      ingress_rules = [
        {
          from_port                = var.standard_ports.https
          to_port                  = var.standard_ports.https
          protocol                 = "tcp"
          source_security_group_id = module.security_groups.security_group_ids["jump-server"]
          description              = "HTTPS access from jump server"
        }
      ]

      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "All outbound traffic"
        }
      ]
    },
    {
      name        = "eks-node-group"
      description = "Rules for EKS node groups"

      ingress_rules = [
        {
          from_port                = var.standard_ports.ssh
          to_port                  = var.standard_ports.ssh
          protocol                 = "tcp"
          source_security_group_id = module.security_groups.security_group_ids["jump-server"]
          description              = "SSH from jump server"
        },
        {
          from_port                = var.standard_ports.https
          to_port                  = var.standard_ports.https
          protocol                 = "tcp"
          source_security_group_id = module.security_groups.security_group_ids["nlb"]
          description              = "HTTPS from NLB"
        },
        {
          from_port                = var.standard_ports.https
          to_port                  = var.standard_ports.https
          protocol                 = "tcp"
          source_security_group_id = module.security_groups.security_group_ids["eks-cluster"]
          description              = "HTTPS from EKS cluster"
        },
        {
          from_port   = 0
          to_port     = 65535
          protocol    = "tcp"
          self        = true
          description = "All TCP between nodes"
        },
        {
          from_port                = var.eks_high_port_range.from
          to_port                  = var.eks_high_port_range.to
          protocol                 = "tcp"
          source_security_group_id = module.security_groups.security_group_ids["eks-cluster"]
          description              = "High ports from cluster"
        }
      ]

      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "All outbound"
        }
      ]
    }
  ]

  depends_on = [module.security_groups]
}

#######################################
#         EKS CLUSTER MODULE          #
#######################################

module "eks_cluster" {
  source       = "./modules/eks-cluster"
  name_prefix  = var.name_prefix
  name_suffix  = var.name_suffix
  general_tags = var.general_tags
  cluster      = var.cluster

  network = merge(
    {
      vpc_id              = module.vpc.vpc_id
      subnet_ids          = concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids)
      security_groups_ids = [module.security_groups.security_group_ids["eks-cluster"]]
    },
    var.cluster_network
  )
}

#######################################
#     EKS NODE GROUPS MODULE          #
#######################################

module "eks_node_groups" {
  source = "./modules/eks-node-groups"

  cluster = {
    name                       = module.eks_cluster.cluster_name
    endpoint                   = module.eks_cluster.cluster_endpoint
    certificate_authority_data = module.eks_cluster.cluster_certificate_authority_data
    version                    = module.eks_cluster.cluster_version
  }

  network = {
    vpc_id              = module.vpc.vpc_id
    subnet_ids          = module.vpc.private_subnet_ids
    security_groups_ids = [module.security_groups.security_group_ids["eks-node-group"]]
  }

  node_groups  = var.eks_node_groups_config.node_groups
  general_tags = var.general_tags
  settings     = var.eks_node_groups_config.settings
  depends_on   = [module.eks_cluster]
}

#######################################
#         EKS ADDONS MODULE           #
#######################################

module "eks_addons" {
  source = "./modules/eks-addons"

  cluster_name = module.eks_cluster.cluster_name
  general_tags = var.general_tags
  name_prefix  = var.name_prefix
  name_suffix  = var.name_suffix
  addons = [
    for addon in var.eks_addons : merge(
      addon,
      addon.name == "aws-ebs-csi-driver" ? {
        service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
      } : {}
    )
  ]
  depends_on = [module.eks_node_groups]
}

#######################################
#              S3 MODULE              #
#######################################

module "s3" {
  source       = "./modules/s3"
  buckets      = var.s3_buckets
  general_tags = var.general_tags
}

#############################################
#         PARAMETER STORE MODULE            #
#############################################

module "parameter_store" {
  source       = "./modules/parameter-store"
  parameters   = var.parameters
  general_tags = var.general_tags
}

#############################################
#                IRSA MODULE                #
#############################################

module "irsa" {
  source                      = "./modules/irsas"
  account_id                  = data.aws_caller_identity.current.account_id
  github_org                  = var.irsa_config.github_org
  main_api_repo_name          = var.irsa_config.main_api_repo_name
  auxiliary_service_repo_name = var.irsa_config.auxiliary_service_repo_name
  general_tags                = var.general_tags
  cluster_name                = module.eks_cluster.cluster_name
  region                      = var.aws_region
  oidc_provider_url           = module.eks_cluster.oidc_provider_url
  oidc_provider_arn           = module.eks_cluster.oidc_provider_arn
  s3_bucket_arns              = module.s3.bucket_arns
}

#############################################
#      MAIN API SSL CERTIFICATE MODULE      #
#############################################

module "domain_certificate" {
  source = "./modules/ssl-certificates"

  domain_name               = var.ssl_certificate.domain_name
  subject_alternative_names = var.ssl_certificate.subject_alternative_names
  certificate_name          = "${var.general_tags.Project}-${var.general_tags.Environment}-main-api"
  auto_validate             = var.auto_validate_certificates

  tags = merge(var.general_tags, {
    Service = "main-api"
  })
}

#######################################
#     K8S BASE RESOURCES MODULE       #
#######################################

module "k8s_resources_custom" {
  source = "./modules/k8s-resources"

  cluster_name            = module.eks_cluster.cluster_name
  cluster_endpoint        = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate  = module.eks_cluster.cluster_certificate_authority_data
  cluster_oidc_issuer_url = module.eks_cluster.oidc_provider_url_https
  oidc_provider_arn       = module.eks_cluster.oidc_provider_arn
  aws_region              = var.aws_region
  vpc_id                  = module.vpc.vpc_id
  tags                    = var.general_tags

  # Component installation flags
  install_metrics_server           = var.k8s_resources_config.install_metrics_server
  install_cluster_autoscaler       = var.k8s_resources_config.install_cluster_autoscaler
  install_load_balancer_controller = var.k8s_resources_config.install_load_balancer_controller
  install_argocd                   = var.k8s_resources_config.install_argocd

  # IRSA configuration
  enable_irsa = var.k8s_resources_config.enable_irsa

  # Namespace configuration
  namespaces = var.namespaces

  # Component configurations
  metrics_server_config     = var.k8s_resources_config.metrics_server_config
  cluster_autoscaler_config = var.k8s_resources_config.cluster_autoscaler_config

  # ArgoCD configuration
  argocd_namespace      = var.k8s_resources_config.argocd_namespace
  argocd_version        = var.k8s_resources_config.argocd_version
  argocd_admin_password = var.k8s_resources_config.argocd_admin_password
  argocd_config = merge(var.k8s_resources_config.argocd_config, {
    acm_certificate_arn: module.domain_certificate.certificate_arn
  })
}
