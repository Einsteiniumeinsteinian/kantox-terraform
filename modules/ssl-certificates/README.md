# AWS SSL Certificates (ACM) Terraform Module

This Terraform module creates and manages AWS Certificate Manager (ACM) SSL/TLS certificates with DNS validation. It provides a streamlined approach to certificate provisioning with support for multiple domains, automatic validation, and comprehensive output for manual DNS configuration.

## Features

- **DNS Validation**: Secure certificate validation through DNS records
- **Multi-Domain Support**: Primary domain with Subject Alternative Names (SANs)
- **Flexible Validation**: Optional automatic validation or manual DNS setup
- **Comprehensive Outputs**: Validation records in multiple formats for easy DNS configuration
- **Lifecycle Management**: Proper certificate lifecycle with create_before_destroy
- **Wildcard Support**: Support for wildcard certificates
- **Regional Deployment**: Deploy certificates in specific AWS regions
- **Tagging Support**: Comprehensive tagging for resource management

## Certificate Types Supported

### Single Domain Certificate

```cert
example.com
```

### Multi-Domain Certificate (SAN)

```cert
Primary: example.com
SANs: www.example.com, api.example.com, admin.example.com
```

### Wildcard

```cert
Primary: *.example.com
SANs: example.com (apex domain)
```

### Multi-Level Wildcard

```cert
Primary: *.example.com
SANs: *.api.example.com, *.admin.example.com
```

## Usage

### Basic Single Domain Certificate

```hcl
module "ssl_certificate" {
  source = "./modules/ssl-certificates"

  domain_name      = "example.com"
  certificate_name = "example-com"
  auto_validate    = false

  tags = {
    Environment = "production"
    Project     = "website"
    Owner       = "platform-team"
    ManagedBy   = "terraform"
  }
}

# Output validation records for manual DNS setup
output "dns_validation_records" {
  value = module.ssl_certificate.validation_records
}
```

### Multi-Domain Certificate with SANs

```hcl
module "multi_domain_certificate" {
  source = "./modules/ssl-certificates"

  domain_name = "example.com"
  subject_alternative_names = [
    "www.example.com",
    "api.example.com",
    "admin.example.com",
    "app.example.com"
  ]
  certificate_name = "example-multi-domain"
  auto_validate    = false

  tags = {
    Environment = "production"
    Project     = "web-application"
    Owner       = "platform-team"
    Team        = "infrastructure"
    ManagedBy   = "terraform"
    Purpose     = "multi-domain-ssl"
  }
}
```

### Wildcard Certificate

```hcl
module "wildcard_certificate" {
  source = "./modules/ssl-certificates"

  domain_name = "*.example.com"
  subject_alternative_names = [
    "example.com"  # Include apex domain
  ]
  certificate_name = "example-wildcard"
  auto_validate    = false

  tags = {
    Environment = "production"
    Project     = "microservices"
    Owner       = "platform-team"
    Team        = "infrastructure"
    ManagedBy   = "terraform"
    CertType    = "wildcard"
  }
}
```

### Auto-Validation Setup (Advanced)

```hcl
# Note: This requires DNS records to be added through external process
module "auto_validated_certificate" {
  source = "./modules/ssl-certificates"

  domain_name = "api.example.com"
  subject_alternative_names = [
    "api-v2.example.com"
  ]
  certificate_name = "api-certificate"
  auto_validate    = true  # Will wait for DNS validation

  tags = {
    Environment = "production"
    Project     = "api-gateway"
    Owner       = "backend-team"
    ManagedBy   = "terraform"
  }
}

# Example of how you might add DNS records externally
# (This is just an example - actual implementation depends on your DNS provider)
resource "cloudflare_record" "cert_validation" {
  for_each = module.auto_validated_certificate.validation_records

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  value   = each.value.value
  type    = each.value.type
  ttl     = 1  # Auto TTL
}
```

### Multi-Environment Certificate Management

```hcl
# Development Environment
module "dev_certificate" {
  source = "./modules/ssl-certificates"

  domain_name = "dev.example.com"
  subject_alternative_names = [
    "*.dev.example.com"
  ]
  certificate_name = "development"
  auto_validate    = false

  tags = {
    Environment = "development"
    Project     = "web-app"
    Owner       = "dev-team"
    ManagedBy   = "terraform"
  }
}

# Staging Environment
module "staging_certificate" {
  source = "./modules/ssl-certificates"

  domain_name = "staging.example.com"
  subject_alternative_names = [
    "*.staging.example.com",
    "api-staging.example.com"
  ]
  certificate_name = "staging"
  auto_validate    = false

  tags = {
    Environment = "staging"
    Project     = "web-app"
    Owner       = "platform-team"
    ManagedBy   = "terraform"
  }
}

# Production Environment
module "production_certificate" {
  source = "./modules/ssl-certificates"

  domain_name = "example.com"
  subject_alternative_names = [
    "www.example.com",
    "api.example.com",
    "admin.example.com",
    "app.example.com",
    "cdn.example.com"
  ]
  certificate_name = "production"
  auto_validate    = false

  tags = {
    Environment = "production"
    Project     = "web-app"
    Owner       = "platform-team"
    Team        = "infrastructure"
    ManagedBy   = "terraform"
    Compliance  = "required"
  }
}
```

### Regional Certificate Deployment

```hcl
# Certificate for CloudFront (must be in us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "cloudfront_certificate" {
  source = "./modules/ssl-certificates"
  
  providers = {
    aws = aws.us_east_1
  }

  domain_name = "cdn.example.com"
  subject_alternative_names = [
    "assets.example.com",
    "static.example.com"
  ]
  certificate_name = "cloudfront-certificate"
  auto_validate    = false

  tags = {
    Environment = "production"
    Project     = "cdn"
    Owner       = "platform-team"
    Purpose     = "cloudfront"
    ManagedBy   = "terraform"
  }
}

# Regional certificate for Application Load Balancer
module "regional_certificate" {
  source = "./modules/ssl-certificates"

  domain_name = "app.example.com"
  subject_alternative_names = [
    "api.example.com"
  ]
  certificate_name = "regional-certificate"
  auto_validate    = false

  tags = {
    Environment = "production"
    Project     = "web-app"
    Owner       = "platform-team"
    Purpose     = "alb"
    ManagedBy   = "terraform"
  }
}
```

### Complete Application Setup

```hcl
# Main application certificate
module "app_certificate" {
  source = "./modules/ssl-certificates"

  domain_name = "myapp.com"
  subject_alternative_names = [
    "www.myapp.com",
    "api.myapp.com",
    "admin.myapp.com",
    "dashboard.myapp.com"
  ]
  certificate_name = "myapp-main"
  auto_validate    = false

  tags = {
    Environment = "production"
    Project     = "myapp"
    Owner       = "platform-team"
    Team        = "infrastructure"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}

# Microservices wildcard certificate
module "microservices_certificate" {
  source = "./modules/ssl-certificates"

  domain_name = "*.services.myapp.com"
  subject_alternative_names = [
    "services.myapp.com"
  ]
  certificate_name = "microservices-wildcard"
  auto_validate    = false

  tags = {
    Environment = "production"
    Project     = "microservices"
    Owner       = "backend-team"
    Team        = "development"
    ManagedBy   = "terraform"
    Purpose     = "microservices"
  }
}

# CDN certificate (us-east-1 for CloudFront)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "cdn_certificate" {
  source = "./modules/ssl-certificates"
  
  providers = {
    aws = aws.us_east_1
  }

  domain_name = "cdn.myapp.com"
  subject_alternative_names = [
    "assets.myapp.com",
    "static.myapp.com",
    "images.myapp.com"
  ]
  certificate_name = "cdn-certificate"
  auto_validate    = false

  tags = {
    Environment = "production"
    Project     = "cdn"
    Owner       = "platform-team"
    Purpose     = "cloudfront"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| domain_name | Primary domain name for the certificate | `string` |
| certificate_name | Name for the certificate (used in tags) | `string` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| subject_alternative_names | Additional domain names for the certificate | `list(string)` | `[]` |
| auto_validate | Whether to automatically validate the certificate | `bool` | `false` |
| tags | Tags to apply to the certificate | `map(string)` | `{}` |

### Variable Details

#### Domain Name Configuration

```hcl
# Single domain
domain_name = "example.com"

# Wildcard domain
domain_name = "*.example.com"

# Subdomain
domain_name = "api.example.com"
```

#### Subject Alternative Names

```hcl
subject_alternative_names = [
  "www.example.com",     # www subdomain
  "api.example.com",     # API subdomain
  "admin.example.com",   # Admin subdomain
  "*.app.example.com"    # Wildcard for app subdomains
]
```

#### Auto Validation

```hcl
# Manual validation (recommended)
auto_validate = false

# Automatic validation (requires external DNS record management)
auto_validate = true
```

## Outputs

| Name | Description |
|------|-------------|
| certificate_arn | ARN of the ACM certificate |
| certificate_status | Status of the certificate |
| validation_records | DNS validation records to add to your domain |
| validation_records_csv | DNS validation records in CSV format |

### Output Examples

#### Certificate ARN

```arn
arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012
```

#### Validation Records

```hcl
validation_records = {
  "example.com" = {
    name  = "_acme-challenge.example.com."
    value = "abc123def456..."
    type  = "CNAME"
  }
  "www.example.com" = {
    name  = "_acme-challenge.www.example.com."
    value = "xyz789uvw456..."
    type  = "CNAME"
  }
}
```

#### CSV Format Output

```csv
Domain,Type,Name,Value
example.com,CNAME,_acme-challenge.example.com.,abc123def456...
www.example.com,CNAME,_acme-challenge.www.example.com.,xyz789uvw456...
```

## DNS Validation Process

### Manual DNS Validation (Recommended)

1. **Deploy the Certificate**

   ```bash
   terraform apply
   ```

2. **Get Validation Records**

   ```bash
   terraform output validation_records
   # Or for CSV format
   terraform output validation_records_csv
   ```

3. **Add DNS Records**
   Add the CNAME records to your DNS provider:

   ```docs
   Name: _acme-challenge.example.com.
   Type: CNAME
   Value: abc123def456...
   TTL: 300 (or your DNS provider's minimum)
   ```

4. **Wait for Validation**
   AWS will automatically detect the DNS records and validate the certificate.

```bash
# Export validation records
terraform output -raw validation_records_csv > dns_records.csv

# Import into your DNS provider's bulk import tool
# Or add records manually through the DNS provider's web interface
```

## Certificate Management

### Certificate Renewal

ACM certificates auto-renew when:

- Certificate is in use by an AWS service
- DNS validation records remain in place
- Certificate is not expired for more than 2 months

### Certificate Monitoring

```hcl
resource "aws_cloudwatch_metric_alarm" "certificate_expiry" {
  alarm_name          = "certificate-expiry-${var.certificate_name}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DaysToExpiry"
  namespace           = "AWS/CertificateManager"
  period              = "86400"  # Daily
  statistic           = "Minimum"
  threshold           = "30"     # Alert 30 days before expiry
  alarm_description   = "Certificate expiring soon"

  dimensions = {
    CertificateArn = module.ssl_certificate.certificate_arn
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

### Certificate Replacement

```hcl
# Create new certificate
module "new_certificate" {
  source = "./modules/ssl-certificates"

  domain_name      = "example.com"
  certificate_name = "example-com-v2"
  auto_validate    = false

  tags = merge(var.common_tags, {
    Version = "v2"
  })
}

# Update services to use new certificate
resource "aws_lb_listener" "https" {
  # ... other configuration
  certificate_arn = module.new_certificate.certificate_arn
}

# Remove old certificate after services are updated
```

## Security Best Practices

### Certificate Scope

1. **Use Specific Domains**: Avoid overly broad wildcard certificates

   ```hcl
   # Good: Specific subdomains
   domain_name = "api.example.com"
   subject_alternative_names = ["www.api.example.com"]

   # Careful: Broad wildcard
   domain_name = "*.example.com"
   ```

2. **Separate Environments**: Use different certificates for different environments

   ```hcl
   # Development
   domain_name = "dev.example.com"

   # Production
   domain_name = "example.com"
   ```

### Access Control

```hcl
# IAM policy for certificate management
data "aws_iam_policy_document" "certificate_manager" {
  statement {
    effect = "Allow"
    actions = [
      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "acm:GetCertificate"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "acm:RequestCertificate",
      "acm:DeleteCertificate",
      "acm:RenewCertificate"
    ]
    resources = [
      "arn:aws:acm:*:*:certificate/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }
}
```

### DNS Security

1. **Secure DNS Provider**: Use reputable DNS providers with security features
2. **DNS Records Protection**: Protect DNS zones from unauthorized changes
3. **Monitoring**: Monitor DNS changes that could affect certificate validation

## Troubleshooting

### Common Issues

1. **Certificate Validation Timeout**

   ```error
   Error: Error waiting for certificate validation: timeout while waiting for state to become 'ISSUED'
   ```

   **Solutions**:
   - Verify DNS records are correctly added
   - Check DNS propagation: `nslookup _acme-challenge.example.com`
   - Ensure TTL is reasonable (300-3600 seconds)

2. **Domain Validation Failed**

   ```error
   Certificate status: VALIDATION_TIMED_OUT
   ```

   **Solutions**:
   - Verify domain ownership
   - Check DNS record values match exactly
   - Ensure DNS zone is publicly accessible

3. **Certificate ARN Not Found**

   ```error
   Error: Certificate not found
   ```

   **Solutions**:
   - Check certificate region matches service region
   - Verify certificate status is ISSUED
   - Use correct certificate ARN

4. **CloudFront Certificate Region Error**

   ```error
   Error: Certificate must be in us-east-1 for CloudFront
   ```

   **Solution**:

   ```hcl
   provider "aws" {
     alias  = "us_east_1"
     region = "us-east-1"
   }

   module "cloudfront_certificate" {
     providers = {
       aws = aws.us_east_1
     }
     # ... other configuration
   }
   ```

### Debugging Commands

```bash
# Check certificate status
aws acm describe-certificate --certificate-arn arn:aws:acm:...

# List all certificates
aws acm list-certificates

# Check DNS validation records
aws acm describe-certificate --certificate-arn arn:aws:acm:... --query 'Certificate.DomainValidationOptions'

# Test DNS resolution
nslookup _acme-challenge.example.com
dig _acme-challenge.example.com CNAME

# Check certificate expiration
aws acm describe-certificate --certificate-arn arn:aws:acm:... --query 'Certificate.NotAfter'
```

### Validation Process Monitoring

```bash
# Monitor certificate validation status
while true; do
  status=$(aws acm describe-certificate --certificate-arn arn:aws:acm:... --query 'Certificate.Status' --output text)
  echo "$(date): Certificate status: $status"
  if [ "$status" = "ISSUED" ]; then
    echo "Certificate validated successfully!"
    break
  elif [ "$status" = "FAILED" ] || [ "$status" = "VALIDATION_TIMED_OUT" ]; then
    echo "Certificate validation failed!"
    break
  fi
  sleep 30
done
```

## Cost Optimization

### Certificate Costs

- **Public Certificates**: Free for AWS services
- **Private Certificates**: Charged monthly
- **DNS Validation**: No additional cost
- **Regional Deployment**: No additional cost per region

### Cost-Effective Strategies

1. **Use Wildcard Certificates**: Reduce number of certificates needed

   ```hcl
   domain_name = "*.example.com"
   subject_alternative_names = ["example.com"]
   ```

2. **Consolidate Domains**: Use SANs instead of separate certificates

   ```hcl
   domain_name = "example.com"
   subject_alternative_names = [
     "www.example.com",
     "api.example.com",
     "admin.example.com"
   ]
   ```

3. **Regional Planning**: Deploy certificates only where needed

   ```hcl
   # Only create CloudFront certificate if using CloudFront
   count = var.enable_cloudfront ? 1 : 0
   ```

## Prerequisites

1. **AWS Account**: Valid AWS account with ACM permissions
2. **Domain Control**: Ability to add DNS records to your domain
3. **DNS Provider**: Access to DNS management for validation
4. **IAM Permissions**: Permissions to create and manage ACM certificates

## Version Compatibility

| Module Version | Terraform | AWS Provider |
|---------------|-----------|--------------|
| 1.x.x         | >= 1.0    | >= 4.0       |

## Best Practices

1. **Certificate Scope**: Use appropriate domain scope (specific vs wildcard)
2. **Environment Separation**: Separate certificates for different environments
3. **Regional Deployment**: Deploy certificates in correct regions for services
4. **Monitoring**: Implement certificate expiration monitoring
5. **Security**: Protect DNS zones and certificate access
6. **Documentation**: Document certificate usage and validation process
7. **Automation**: Automate DNS validation where possible
8. **Backup**: Keep records of certificate configurations

## Contributing

When contributing to this module:

1. Test with different domain configurations
2. Verify DNS validation process
3. Test with multiple AWS services
4. Ensure regional deployment works correctly
5. Update documentation for new features
6. Test certificate renewal process

## License

This module is provided under the MIT License. See LICENSE file for details.
