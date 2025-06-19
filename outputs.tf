# # outputs.tf
output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks_cluster.cluster_name
}

output "created_namespaces" {
  description = "List of created namespaces"
  value = module.k8s_resources_custom.created_namespaces 
}

output "vpc_id" {
  description = "The ID of the created VPC"
  value       = module.vpc.vpc_id
}

# Certificate Outputs
output "domain_certificate_arn" {
  description = "ARN of the domain certificate"
  value       = module.domain_certificate.certificate_arn
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig on the jump server"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks_cluster.cluster_name}"
}

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN"
  value       = module.irsa.github_oidc_provider_arn
}

output "github_repo_secrets_note" {
  description = "Reminder to configure required GitHub repository secrets"
  value = <<-EOT

    ✅ Ensure the following GitHub repository secrets are configured for GitHub Actions:

    - AWS_REGION           → ${var.aws_region}
    - AWS_ACCOUNT_ID       → ${data.aws_caller_identity.current.account_id}
    - AWS_ROLE_ARN_MAIN    → ${module.irsa.main_api_role_arn}
    - AWS_ROLE_ARN_AUX     → ${module.irsa.auxiliary_service_role_arn}
    - ECR_REPOSITORY_MAIN  → ${aws_ecr_repository.repos["main-api"].name}
    - ECR_REPOSITORY_AUX   → ${aws_ecr_repository.repos["auxiliary-service"].name}

    🔐 These secrets are used in your GitHub Actions workflows to authenticate with AWS, push to ECR, and deploy to EKS.

  EOT
}



# Instructions
output "next_steps" {
  description = "Instructions for next steps"
  value = <<-EOT
    
    NEXT STEPS:
    
    1. Add these DNS records to Namecheap:
       ${module.domain_certificate.validation_records_csv}
    
    2. Point your domain to the ALB:
       - Type: CNAME
       - Host: main-api
       - Value: Load balancer IP
    
    3. Wait for certificate validation (5-10 minutes after adding DNS records)
    
    4. Use this certificate ARN in your Kubernetes Ingress:
       ${module.domain_certificate.certificate_arn}
    
    5. Use this ALB group name in your Ingress annotations:
       alb.ingress.kubernetes.io/group.name: "main-dev"
  
  EOT
}
