# modules/k8s-resources/outputs.tf

output "created_namespaces" {
  description = "List of created namespaces"
  value = {
    for k, v in kubernetes_namespace.namespaces : k => {
      name = v.metadata[0].name
      uid  = v.metadata[0].uid
    }
  }
}

output "metrics_server" {
  description = "Metrics server information"
  value = var.install_metrics_server ? {
    installed = true
    version   = var.metrics_server_version
    status    = helm_release.metrics_server[0].status
  } : {
    installed = false
  }
}

output "cluster_autoscaler" {
  description = "Cluster autoscaler information"
  value = var.install_cluster_autoscaler ? {
    installed    = true
    version      = var.cluster_autoscaler_version
    iam_role_arn = aws_iam_role.cluster_autoscaler[0].arn
    status       = helm_release.cluster_autoscaler[0].status
  } : {
    installed = false
  }
}

output "load_balancer_controller" {
  description = "AWS Load Balancer Controller information"
  value = var.install_load_balancer_controller ? {
    installed    = true
    version      = var.load_balancer_controller_version
    iam_role_arn = aws_iam_role.aws_load_balancer_controller[0].arn
    status       = helm_release.aws_load_balancer_controller[0].status
  } : {
    installed = false
  }
}

output "argocd" {
  description = "ArgoCD information"
  value = var.install_argocd ? {
    installed                = true
    version                  = var.argocd_version
    namespace                = var.argocd_namespace
    status                   = helm_release.argocd[0].status
    server_url               = var.argocd_config.enable_ingress && length(var.argocd_config.ingress_host) > 0 ? (
      var.argocd_config.enable_tls ? "https://${var.argocd_config.ingress_host}" : "http://${var.argocd_config.ingress_host}"
    ) : null
    ingress_enabled          = var.argocd_config.enable_ingress
    tls_enabled             = var.argocd_config.enable_tls
    ha_enabled              = var.argocd_config.ha_enabled
    metrics_enabled         = var.argocd_config.enable_metrics
    applicationset_enabled  = var.argocd_config.enable_applicationset
    notifications_enabled   = var.argocd_config.enable_notifications
    admin_password_secret   = length(var.argocd_admin_password) > 0 ? "argocd-initial-admin-secret" : null
    load_balancer_hostname  = var.argocd_config.enable_ingress ? (
      try(data.kubernetes_ingress_v1.argocd_ingress[0].status[0].load_balancer[0].ingress[0].hostname, null)
    ) : null
  } : {
    installed = false
  }
}

output "component_status" {
  description = "Status of all components"
  value = {
    metrics_server            = var.install_metrics_server
    cluster_autoscaler        = var.install_cluster_autoscaler
    load_balancer_controller  = var.install_load_balancer_controller
    argocd                   = var.install_argocd
    namespaces_count         = length(var.namespaces)
    oidc_provider_created    = var.enable_irsa
  }
}

output "service_account_annotations" {
  description = "Service account annotations for IRSA"
  value = {
    cluster_autoscaler = var.install_cluster_autoscaler ? {
      "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler[0].arn
    } : {}
    load_balancer_controller = var.install_load_balancer_controller ? {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller[0].arn
    } : {}
  }
}

# Data source to get ingress details after creation
data "kubernetes_ingress_v1" "argocd_ingress" {
  count = var.install_argocd && var.argocd_config.enable_ingress ? 1 : 0
  
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.namespaces[var.argocd_namespace].metadata[0].name
  }
  
  depends_on = [helm_release.argocd]
}