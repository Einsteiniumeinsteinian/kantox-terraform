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
    metrics_enabled         = var.argocd_config.enable_metrics
    applicationset_enabled  = var.argocd_config.enable_applicationset
    notifications_enabled   = var.argocd_config.enable_notifications
    admin_password_secret   = length(var.argocd_admin_password) > 0 ? "argocd-initial-admin-secret" : null
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
