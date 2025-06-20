# modules/k8s-resources/main.tf
# Data source for TLS certificate (needed for OIDC provider)
data "tls_certificate" "cluster" {
  count = var.enable_irsa ? 1 : 0
  url   = var.cluster_oidc_issuer_url
}

# Local values
locals {
  common_tags = merge({
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "k8s-component"                             = "true"
  }, var.tags)

  # OIDC issuer URL without https://
  oidc_issuer_url = replace(var.cluster_oidc_issuer_url, "https://", "")
}

# =============================================================================
# OIDC PROVIDER FOR IRSA (if enabled)
# =============================================================================

# Use existing OIDC provider if not creating new one
data "aws_iam_openid_connect_provider" "existing" {
  count = var.enable_irsa ? 0 : 1
  url   = var.cluster_oidc_issuer_url
}

locals {
  oidc_provider_arn = var.enable_irsa ? var.oidc_provider_arn : data.aws_iam_openid_connect_provider.existing[0].arn
}

# =============================================================================
# NAMESPACES
# =============================================================================

resource "kubernetes_namespace" "namespaces" {
  for_each = {
    for ns in var.namespaces : ns.name => ns
  }

  metadata {
    name        = each.value.name
    labels      = each.value.labels
    annotations = each.value.annotations
  }

    lifecycle {
    ignore_changes = [
      metadata[0].labels,
      metadata[0].annotations
    ]
  }
}

# =============================================================================
# METRICS SERVER
# =============================================================================

resource "helm_release" "metrics_server" {
  count = var.install_metrics_server ? 1 : 0

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = var.metrics_server_version

  dynamic "set" {
    for_each = var.metrics_server_config.kubelet_insecure_tls ? [1] : []
    content {
      name  = "args[0]"
      value = "--kubelet-insecure-tls"
    }
  }

  set_list {
    name = "args"
    value = concat(
      var.metrics_server_config.kubelet_insecure_tls ? ["--kubelet-insecure-tls"] : [],
      length(var.metrics_server_config.kubelet_preferred_address_types) > 0 ? [
        "--kubelet-preferred-address-types=${join(",", var.metrics_server_config.kubelet_preferred_address_types)}"
      ] : []
    )
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "200Mi"
  }
}

# =============================================================================
# CLUSTER AUTOSCALER IAM ROLE AND POLICY
# =============================================================================

resource "aws_iam_role" "cluster_autoscaler" {
  count = var.install_cluster_autoscaler ? 1 : 0

  name = "${var.cluster_name}-cluster-autoscaler"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = local.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${local.oidc_issuer_url}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
          "${local.oidc_issuer_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
    Version = "2012-10-17"
  })

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-cluster-autoscaler-role"
  })
}

resource "aws_iam_policy" "cluster_autoscaler" {
  count = var.install_cluster_autoscaler ? 1 : 0

  name        = "${var.cluster_name}-cluster-autoscaler-policy"
  description = "IAM policy for cluster autoscaler"

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeInstanceTypes"
        ]
        Resource = "*"
      }
    ]
    Version = "2012-10-17"
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count = var.install_cluster_autoscaler ? 1 : 0

  role       = aws_iam_role.cluster_autoscaler[0].name
  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
}

# =============================================================================
# CLUSTER AUTOSCALER HELM CHART
# =============================================================================

resource "helm_release" "cluster_autoscaler" {
  count = var.install_cluster_autoscaler ? 1 : 0

  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = var.cluster_autoscaler_version

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name  = "rbac.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cluster_autoscaler[0].arn
  }

  set {
    name  = "extraArgs.scale-down-delay-after-add"
    value = var.cluster_autoscaler_config.scale_down_delay_after_add
  }

  set {
    name  = "extraArgs.scale-down-unneeded-time"
    value = var.cluster_autoscaler_config.scale_down_unneeded_time
  }

  set {
    name  = "extraArgs.scale-down-utilization-threshold"
    value = var.cluster_autoscaler_config.scale_down_utilization_threshold
  }

  set {
    name  = "extraArgs.skip-nodes-with-local-storage"
    value = var.cluster_autoscaler_config.skip_nodes_with_local_storage
  }

  set {
    name  = "extraArgs.skip-nodes-with-system-pods"
    value = var.cluster_autoscaler_config.skip_nodes_with_system_pods
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "300Mi"
  }

  depends_on = [
    helm_release.metrics_server,
    aws_iam_role_policy_attachment.cluster_autoscaler,
  ]
}

# =============================================================================
# AWS LOAD BALANCER CONTROLLER IAM ROLE AND POLICY
# =============================================================================

# Download the official policy
data "http" "aws_load_balancer_controller_policy" {
  count = var.install_load_balancer_controller ? 1 : 0
  url   = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/${var.load_balancer_controller_policy_version}/docs/install/iam_policy.json"
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  count = var.install_load_balancer_controller ? 1 : 0

  name = "${var.cluster_name}-alb-controller"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = local.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${local.oidc_issuer_url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          "${local.oidc_issuer_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
    Version = "2012-10-17"
  })

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-alb-controller-role"
  })
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  count = var.install_load_balancer_controller ? 1 : 0

  name        = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
  description = "AWS Load Balancer Controller IAM Policy"
  policy      = data.http.aws_load_balancer_controller_policy[0].response_body

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  count = var.install_load_balancer_controller ? 1 : 0

  policy_arn = aws_iam_policy.aws_load_balancer_controller[0].arn
  role       = aws_iam_role.aws_load_balancer_controller[0].name
}

# =============================================================================
# AWS LOAD BALANCER CONTROLLER HELM CHART
# =============================================================================

resource "helm_release" "aws_load_balancer_controller" {
  count = var.install_load_balancer_controller ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = var.load_balancer_controller_version

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller[0].arn
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "200Mi"
  }

  depends_on = [
    helm_release.metrics_server,
    aws_iam_role_policy_attachment.aws_load_balancer_controller,
  ]
}

# =============================================================================
# ARGOCD HELM CHART
# =============================================================================

resource "helm_release" "argocd" {
  count = var.install_argocd ? 1 : 0

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.namespaces[var.argocd_namespace].metadata[0].name
  version    = var.argocd_version

  # Server configuration
  set {
    name  = "server.service.type"
    value = var.argocd_config.server_service_type
  }

  set {
    name  = "server.config.application.instanceLabelKey"
    value = "argocd.argoproj.io/instance"
  }

  # RBAC configuration
  set {
    name  = "server.rbacConfig.policy\\.default"
    value = "role:readonly"
  }

set {
  name  = "server.rbacConfig.policy\\.csv"
  value = "g\\,argocd-admin\\,role:admin"
}
  # Repository server configuration
  set {
    name  = "repoServer.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "repoServer.resources.requests.memory"
    value = "256Mi"
  }

  # Controller configuration
  set {
    name  = "controller.resources.requests.cpu"
    value = "250m"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "512Mi"
  }

  # Server resources
  set {
    name  = "server.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "server.resources.requests.memory"
    value = "256Mi"
  }

  # Enable metrics
  set {
    name  = "controller.metrics.enabled"
    value = var.argocd_config.enable_metrics
  }

  set {
    name  = "server.metrics.enabled"
    value = var.argocd_config.enable_metrics
  }

  set {
    name  = "repoServer.metrics.enabled"
    value = var.argocd_config.enable_metrics
  }

  # High availability configuration
  dynamic "set" {
    for_each = var.argocd_config.ha_enabled ? [1] : []
    content {
      name  = "controller.replicas"
      value = "2"
    }
  }

  dynamic "set" {
    for_each = var.argocd_config.ha_enabled ? [1] : []
    content {
      name  = "server.replicas"
      value = "2"
    }
  }

  dynamic "set" {
    for_each = var.argocd_config.ha_enabled ? [1] : []
    content {
      name  = "repoServer.replicas"
      value = "2"
    }
  }

  # Redis HA configuration
  dynamic "set" {
    for_each = var.argocd_config.ha_enabled ? [1] : []
    content {
      name  = "redis-ha.enabled"
      value = "true"
    }
  }

  dynamic "set" {
    for_each = var.argocd_config.ha_enabled ? [1] : []
    content {
      name  = "redis.enabled"
      value = "false"
    }
  }

  # Notifications configuration
  dynamic "set" {
    for_each = var.argocd_config.enable_notifications ? [1] : []
    content {
      name  = "notifications.enabled"
      value = "true"
    }
  }

  # ApplicationSet controller
  dynamic "set" {
    for_each = var.argocd_config.enable_applicationset ? [1] : []
    content {
      name  = "applicationSet.enabled"
      value = "true"
    }
  }

  depends_on = [
    kubernetes_namespace.namespaces,
    helm_release.metrics_server,
  ]
}

# =============================================================================
# ARGOCD INITIAL ADMIN PASSWORD SECRET (optional)
# =============================================================================

resource "kubernetes_secret" "argocd_initial_admin_secret" {
  count = var.install_argocd && length(var.argocd_admin_password) > 0 ? 1 : 0

  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace.namespaces[var.argocd_namespace].metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "argocd-initial-admin-secret"
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  data = {
    password = bcrypt(var.argocd_admin_password)
  }

  type = "Opaque"

    lifecycle {
    ignore_changes = [data]
  }

  depends_on = [
    kubernetes_namespace.namespaces,
  ]
}
