# =============================================================================
# EKS CLUSTER MODULE
# =============================================================================

# modules/eks-cluster/main.tf

locals {
  prefix_dash = var.name_prefix != "" ? "${var.name_prefix}-" : ""
  suffix_dash = var.name_suffix != "" ? "-${var.name_suffix}" : ""

  cluster_name = "${local.prefix_dash}${var.general_tags.Environment}-${var.general_tags.Project}-${var.cluster.name}-cluster${local.suffix_dash}"
}

# IAM Role for EKS Cluster
data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${local.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = merge(
    var.general_tags,
    {
      Name = "${local.cluster_name}-cluster-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "eks_cluster" {
  count = length(var.cluster.enable_cluster_log_types) > 0 ? 1 : 0

  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = var.cluster.log_retention_in_days

  tags = merge(
    var.general_tags,
    {
      Name = "${local.cluster_name}-log-group"
    }
  )
}

# KMS Key for EKS Encryption
resource "aws_kms_key" "eks" {
  count = var.cluster.enable_encryption ? 1 : 0

  description             = "EKS Secret Encryption Key for ${local.cluster_name}"
  deletion_window_in_days = var.cluster.kms_key_deletion_window
  enable_key_rotation     = true

  tags = merge(
    var.general_tags,
    {
      Name = "${local.cluster_name}-encryption-key"
    }
  )
}

resource "aws_kms_alias" "eks" {
  count = var.cluster.enable_encryption ? 1 : 0

  name          = "alias/${local.cluster_name}-kms"
  target_key_id = aws_kms_key.eks[0].key_id
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.cluster.version

  vpc_config {
    subnet_ids              = var.network.subnet_ids
    endpoint_private_access = var.network.endpoint_private_access
    endpoint_public_access  = var.network.endpoint_public_access
    public_access_cidrs     = var.network.public_access_cidrs
    security_group_ids      = var.network.security_groups_ids
  }

  dynamic "encryption_config" {
    for_each = var.cluster.enable_encryption ? [1] : []
    content {
      provider {
        key_arn = aws_kms_key.eks[0].arn
      }
      resources = ["secrets"]
    }
  }

  enabled_cluster_log_types = var.cluster.enable_cluster_log_types

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
    aws_cloudwatch_log_group.eks_cluster,
  ]

  tags = merge(
    var.general_tags,
    {
      Name = "${local.cluster_name}"
    }
  )
}

# OIDC Provider
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(
    var.general_tags,
    {
      Name = "${local.cluster_name}-oidc-provider"
    }
  )
}
