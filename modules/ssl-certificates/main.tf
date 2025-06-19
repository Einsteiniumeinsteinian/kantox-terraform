# modules/ssl-certificates/main.tf

# ACM Certificate
resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.certificate_name}-certificate"
  })
}

# Output validation records for manual DNS setup
locals {
  validation_records = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      value = dvo.resource_record_value
      type  = dvo.resource_record_type
    }
  }
}

# If auto_validate is true, wait for certificate validation
# Note: This will only work if DNS records are added externally
resource "aws_acm_certificate_validation" "main" {
  count           = var.auto_validate ? 1 : 0
  certificate_arn = aws_acm_certificate.main.arn

  timeouts {
    create = "10m"
  }

  # This will wait indefinitely until validation records are added to DNS
  depends_on = [aws_acm_certificate.main]
}
