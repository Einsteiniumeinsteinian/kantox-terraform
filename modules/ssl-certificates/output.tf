# modules/ssl-certificates/outputs.tf

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = var.auto_validate ? aws_acm_certificate_validation.main[0].certificate_arn : aws_acm_certificate.main.arn
}

output "certificate_status" {
  description = "Status of the certificate"
  value       = aws_acm_certificate.main.status
}

output "validation_records" {
  description = "DNS validation records to add to your domain"
  value = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      value = dvo.resource_record_value
      type  = dvo.resource_record_type
    }
  }
}

output "validation_records_csv" {
  description = "DNS validation records in CSV format for easy copying"
  value = "Domain,Type,Name,Value\n${join("\n", [
    for dvo in aws_acm_certificate.main.domain_validation_options :
    "${dvo.domain_name},${dvo.resource_record_type},${dvo.resource_record_name},${dvo.resource_record_value}"
  ])}"
}