# terraform/modules/iam/outputs.tf
output "service_account_roles" {
  description = "IAM roles for service accounts"
  value = {
    auxiliary_service = {
      arn  = aws_iam_role.auxiliary_service.arn
      name = aws_iam_role.auxiliary_service.name
    }
  }
}

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "main_api_role_arn" {
  description = "ARN of the Main API GitHub Actions role"
  value       = aws_iam_role.github_actions_main_api.arn
}

output "auxiliary_service_role_arn" {
  description = "ARN of the Auxiliary Service GitHub Actions role"
  value       = aws_iam_role.github_actions_auxiliary_service.arn
}