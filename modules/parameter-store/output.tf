# terraform/modules/parameter-store/outputs.tf
output "parameters" {
  description = "Parameter Store parameters"
  value = {
    for k, v in aws_ssm_parameter.parameters : k => {
      name = v.name
      arn  = v.arn
      type = v.type
    }
  }
}

output "parameter_names" {
  description = "Parameter Store parameter names"
  value       = [for param in aws_ssm_parameter.parameters : param.name]
}

output "parameter_arns" {
  description = "Parameter Store parameter ARNs"
  value       = [for param in aws_ssm_parameter.parameters : param.arn]
}

