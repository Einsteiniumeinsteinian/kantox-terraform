# AWS S3 Terraform Module

This Terraform module creates and manages multiple AWS S3 buckets with a standardized naming convention, security best practices, and configurable features. It provides a secure, consistent, and scalable approach to S3 bucket management across different environments and use cases.

## Features

- **Multiple Buckets**: Create multiple S3 buckets with different configurations in a single module call
- **Standardized Naming**: Consistent bucket naming convention with environment, purpose, and project organization
- **Security by Default**: Public access blocked by default with optional encryption
- **Versioning Control**: Configurable object versioning per bucket
- **Encryption Support**: Server-side encryption with AES256 and bucket key optimization
- **Flexible Configuration**: Customizable settings for different bucket purposes
- **Comprehensive Tagging**: Automatic tagging with environment, project, and purpose metadata
- **Name Customization**: Optional prefix and suffix for bucket names

## Bucket Naming Convention

The module follows a standardized naming pattern:

```
{prefix}-{environment}-{purpose}-{project}-{suffix}
```

**Examples:**
- `production-uploads-myapp` (without prefix/suffix)
- `company-production-logs-myapp-v1` (with prefix and suffix)
- `staging-backups-ecommerce` (staging environment)

## Usage

### Basic Example

```hcl
module "s3_buckets" {
  source = "./terraform/modules/s3"

  buckets = {
    uploads = {
      versioning = true
      encryption = true
    }
    logs = {
      versioning = false
      encryption = true
    }
    backups = {
      versioning = true
      encryption = true
    }
  }

  general_tags = {
    Environment = "production"
    Project     = "myapp"
    Owner       = "platform-team"
    Team        = "infrastructure"
    ManagedBy   = "terraform"
  }
}
```

### Complete Application Storage Setup

```hcl
module "application_storage" {
  source = "./terraform/modules/s3"

  buckets = {
    # User file uploads
    uploads = {
      versioning = true   # Keep file versions for recovery
      encryption = true   # Encrypt sensitive user data
    }
    
    # Application logs and metrics
    logs = {
      versioning = false  # Logs don't need versioning
      encryption = true   # Encrypt for compliance
    }
    
    # Database and application backups
    backups = {
      versioning = true   # Multiple backup versions
      encryption = true   # Secure backup storage
    }
    
    # Static assets (CSS, JS, images)
    assets = {
      versioning = false  # Static assets don't change frequently
      encryption = false  # Public assets don't need encryption
    }
    
    # Data processing and analytics
    analytics = {
      versioning = false  # Large datasets, versioning not practical
      encryption = true   # Sensitive business data
    }
    
    # Document storage and archives
    documents = {
      versioning = true   # Document history important
      encryption = true   # Sensitive documents
    }
  }

  name_prefix = "company"
  name_suffix = "v2"

  general_tags = {
    Environment = "production"
    Project     = "ecommerce"
    Owner       = "platform-team"
    Team        = "infrastructure"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}
```

### Multi-Environment Setup

```hcl
# Development Environment
module "s3_development" {
  source = "./terraform/modules/s3"

  buckets = {
    uploads = {
      versioning = false  # Save costs in development
      encryption = false  # Faster development workflow
    }
    logs = {
      versioning = false
      encryption = false
    }
    testing = {
      versioning = false  # Test data bucket
      encryption = false
    }
  }

  general_tags = {
    Environment = "development"
    Project     = "myapp"
    Owner       = "dev-team"
    Team        = "engineering"
    ManagedBy   = "terraform"
  }
}

# Staging Environment
module "s3_staging" {
  source = "./terraform/modules/s3"

  buckets = {
    uploads = {
      versioning = true   # Test versioning features
      encryption = true   # Match production security
    }
    logs = {
      versioning = false
      encryption = true
    }
    backups = {
      versioning = true
      encryption = true
    }
  }

  general_tags = {
    Environment = "staging"
    Project     = "myapp"
    Owner       = "platform-team"
    Team        = "infrastructure"
    ManagedBy   = "terraform"
  }
}

# Production Environment
module "s3_production" {
  source = "./terraform/modules/s3"

  buckets = {
    uploads = {
      versioning = true   # Data protection
      encryption = true   # Security compliance
    }
    logs = {
      versioning = false  # Cost optimization
      encryption = true   # Audit requirements
    }
    backups = {
      versioning = true   # Multiple backup generations
      encryption = true   # Secure backups
    }
    archives = {
      versioning = true   # Long-term storage
      encryption = true   # Compliance requirements
    }
  }

  name_prefix = "prod"

  general_tags = {
    Environment = "production"
    Project     = "myapp"
    Owner       = "platform-team"
    Team        = "infrastructure"
    ManagedBy   = "terraform"
    Backup      = "required"
    Compliance  = "sox-pci"
  }
}
```

### Specialized Use Cases

```hcl
# Data Lake Setup
module "data_lake" {
  source = "./terraform/modules/s3"

  buckets = {
    raw-data = {
      versioning = false  # Large datasets, single version
      encryption = true   # Sensitive data protection
    }
    processed-data = {
      versioning = false  # Processed output
      encryption = true   # Analytics data protection
    }
    ml-models = {
      versioning = true   # Model versioning important
      encryption = true   # IP protection
    }
    feature-store = {
      versioning = false  # Large feature datasets
      encryption = true   # Data privacy
    }
  }

  name_prefix = "analytics"

  general_tags = {
    Environment = "production"
    Project     = "data-platform"
    Owner       = "data-team"
    Team        = "analytics"
    ManagedBy   = "terraform"
    Purpose     = "data-lake"
  }
}

# Content Management System
module "cms_storage" {
  source = "./terraform/modules/s3"

  buckets = {
    media = {
      versioning = true   # Media file versions
      encryption = false  # Public content
    }
    templates = {
      versioning = true   # Template history
      encryption = false  # Public templates
    }
    user-content = {
      versioning = true   # User-generated content
      encryption = true   # Privacy protection
    }
    cache = {
      versioning = false  # Temporary cache data
      encryption = false  # Performance optimization
    }
  }

  general_tags = {
    Environment = "production"
    Project     = "cms"
    Owner       = "content-team"
    Team        = "frontend"
    ManagedBy   = "terraform"
  }
}

# Compliance and Audit Storage
module "compliance_storage" {
  source = "./terraform/modules/s3"

  buckets = {
    audit-logs = {
      versioning = true   # Audit trail integrity
      encryption = true   # Compliance requirement
    }
    compliance-docs = {
      versioning = true   # Document history
      encryption = true   # Sensitive compliance data
    }
    archived-data = {
      versioning = true   # Long-term retention
      encryption = true   # Data protection
    }
  }

  name_prefix = "compliance"
  name_suffix = "secure"

  general_tags = {
    Environment = "production"
    Project     = "governance"
    Owner       = "compliance-team"
    Team        = "legal"
    ManagedBy   = "terraform"
    Retention   = "7-years"
    Compliance  = "sox-gdpr"
  }
}
```

## Inputs

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| general_tags | Global required tags for all resources | `object` |
| buckets | S3 buckets configuration | `map(object)` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| name_prefix | Prefix for bucket names | `string` | `""` |
| name_suffix | Suffix for bucket names | `string` | `""` |

### General Tags Object Structure

```hcl
general_tags = {
  Environment = string                          # Environment name (e.g., "production", "staging")
  Owner       = string                          # Owner of the resources
  Project     = string                          # Project name
  Team        = string                          # Team responsible
  ManagedBy   = optional(string, "terraform")   # Management tool
}
```

### Buckets Configuration

```hcl
buckets = {
  bucket_purpose = {
    versioning = bool  # Enable/disable object versioning
    encryption = bool  # Enable/disable server-side encryption
  }
}
```

**Configuration Options:**
- **versioning**: Controls S3 object versioning
  - `true`: Keep multiple versions of objects (recovery, compliance)
  - `false`: Single version only (cost optimization)
- **encryption**: Controls server-side encryption
  - `true`: AES256 encryption with bucket key optimization
  - `false`: No encryption (public content, performance)

## Outputs

| Name | Description |
|------|-------------|
| buckets | Complete bucket information with IDs, ARNs, domains, and regions |
| bucket_names | List of all bucket names |
| bucket_arns | List of all bucket ARNs |

### Output Structures

#### Buckets Output
```hcl
buckets = {
  uploads = {
    id     = "production-uploads-myapp"
    arn    = "arn:aws:s3:::production-uploads-myapp"
    domain = "production-uploads-myapp.s3.amazonaws.com"
    region = "us-west-2"
  }
  logs = {
    id     = "production-logs-myapp"
    arn    = "arn:aws:s3:::production-logs-myapp"
    domain = "production-logs-myapp.s3.amazonaws.com"
    region = "us-west-2"
  }
}
```

## Security Features

### Public Access Block

All buckets created by this module have public access blocked by default:

```hcl
block_public_acls       = true   # Block public ACLs
block_public_policy     = true   # Block public bucket policies
ignore_public_acls      = true   # Ignore existing public ACLs
restrict_public_buckets = true   # Restrict public bucket policies
```

This configuration ensures:
- No public read/write access via ACLs
- No public access via bucket policies
- Protection against accidental public exposure

### Server-Side Encryption

When encryption is enabled:
- **Algorithm**: AES256 (Amazon S3 managed keys)
- **Bucket Key**: Enabled for cost optimization
- **Default Encryption**: Applied to all objects

```hcl
rule {
  apply_server_side_encryption_by_default {
    sse_algorithm = "AES256"
  }
  bucket_key_enabled = true
}
```

### Versioning Configuration

Object versioning provides:
- **Data Protection**: Recovery from accidental deletion or modification
- **Compliance**: Audit trail for data changes
- **Backup Strategy**: Multiple object versions for different backup generations

## Best Practices Implementation

### Naming Conventions

1. **Consistent Structure**: `{prefix}-{environment}-{purpose}-{project}-{suffix}`
2. **Descriptive Purpose**: Clear indication of bucket usage
3. **Environment Separation**: Explicit environment identification
4. **Project Grouping**: Logical grouping by project

### Security Defaults

1. **Public Access Blocked**: All buckets private by default
2. **Encryption Available**: Easy encryption enablement
3. **Versioning Control**: Configurable based on use case
4. **Comprehensive Tagging**: Detailed resource metadata

### Cost Optimization

1. **Selective Versioning**: Enable only when needed
2. **Encryption Choice**: Balance security with performance
3. **Bucket Key**: Enabled for encryption cost reduction
4. **Purpose-Based Configuration**: Different settings for different use cases

## Integration Examples

### With CloudFront for Static Website

```hcl
module "website_buckets" {
  source = "./terraform/modules/s3"

  buckets = {
    website = {
      versioning = false  # Static content
      encryption = false  # Public website content
    }
    assets = {
      versioning = false  # CSS, JS, images
      encryption = false  # Public assets
    }
  }

  general_tags = var.common_tags
}

resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name = module.website_buckets.buckets.website.domain
    origin_id   = "S3-${module.website_buckets.buckets.website.id}"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website.cloudfront_access_identity_path
    }
  }
  
  # CloudFront configuration...
}
```

### With Lambda for Data Processing

```hcl
module "data_buckets" {
  source = "./terraform/modules/s3"

  buckets = {
    input = {
      versioning = false
      encryption = true
    }
    output = {
      versioning = false
      encryption = true
    }
    processed = {
      versioning = true   # Keep processing history
      encryption = true
    }
  }

  general_tags = var.common_tags
}

resource "aws_lambda_function" "data_processor" {
  filename         = "data_processor.zip"
  function_name    = "data-processor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"

  environment {
    variables = {
      INPUT_BUCKET    = module.data_buckets.buckets.input.id
      OUTPUT_BUCKET   = module.data_buckets.buckets.output.id
      PROCESSED_BUCKET = module.data_buckets.buckets.processed.id
    }
  }
}

resource "aws_s3_bucket_notification" "data_processing" {
  bucket = module.data_buckets.buckets.input.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.data_processor.arn
    events             = ["s3:ObjectCreated:*"]
  }
}
```

### With Application for File Storage

```hcl
module "app_storage" {
  source = "./terraform/modules/s3"

  buckets = {
    uploads = {
      versioning = true
      encryption = true
    }
    temp = {
      versioning = false
      encryption = false
    }
  }

  general_tags = var.common_tags
}

# IAM policy for application access
resource "aws_iam_policy" "app_s3_access" {
  name        = "${var.app_name}-s3-access"
  description = "S3 access for application"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${module.app_storage.buckets.uploads.arn}/*",
          "${module.app_storage.buckets.temp.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          module.app_storage.buckets.uploads.arn,
          module.app_storage.buckets.temp.arn
        ]
      }
    ]
  })
}
```

## Lifecycle Management

### Automatic Lifecycle Rules

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = module.s3_buckets.buckets.uploads.id

  rule {
    id     = "uploads_lifecycle"
    status = "Enabled"

    # Delete incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # Transition to IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Delete after 7 years
    expiration {
      days = 2555
    }

    # Clean up old versions
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
```

### Backup and Replication

```hcl
# Cross-region replication for critical data
resource "aws_s3_bucket_replication_configuration" "backups" {
  role   = aws_iam_role.replication.arn
  bucket = module.s3_buckets.buckets.backups.id

  rule {
    id     = "replicate_backups"
    status = "Enabled"

    destination {
      bucket        = "arn:aws:s3:::${var.backup_region}-backups-${var.project}"
      storage_class = "STANDARD_IA"
    }
  }

  depends_on = [aws_s3_bucket_versioning.buckets]
}
```

## Monitoring and Alerting

### CloudWatch Metrics

```hcl
resource "aws_cloudwatch_metric_alarm" "bucket_size" {
  for_each = module.s3_buckets.buckets

  alarm_name          = "${each.value.id}-bucket-size"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = "86400"  # Daily
  statistic           = "Average"
  threshold           = "10737418240"  # 10GB
  alarm_description   = "This metric monitors S3 bucket size"

  dimensions = {
    BucketName = each.value.id
    StorageType = "StandardStorage"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

### Access Logging

```hcl
resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.environment}-access-logs-${var.project}"

  tags = var.common_tags
}

resource "aws_s3_bucket_logging" "buckets" {
  for_each = module.s3_buckets.buckets

  bucket = each.value.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "${each.key}/"
}
```

## Cost Management

### Storage Class Optimization

1. **Standard**: Frequently accessed data
2. **Standard-IA**: Infrequently accessed data (backups, archives)
3. **Glacier**: Long-term archival with retrieval times
4. **Deep Archive**: Lowest cost for rarely accessed data

### Cost Monitoring

```hcl
resource "aws_budgets_budget" "s3_costs" {
  name         = "${var.project}-s3-budget"
  budget_type  = "COST"
  limit_amount = "100"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filters {
    service = ["Amazon Simple Storage Service"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
}
```

## Troubleshooting

### Common Issues

1. **Bucket Name Conflicts**
   ```bash
   # Check if bucket name is available
   aws s3api head-bucket --bucket "production-uploads-myapp" 2>/dev/null
   echo $?  # 0 = exists, 254 = doesn't exist
   ```

2. **Access Denied Errors**
   ```bash
   # Check bucket policy and ACLs
   aws s3api get-bucket-policy --bucket "production-uploads-myapp"
   aws s3api get-bucket-acl --bucket "production-uploads-myapp"
   ```

3. **Encryption Issues**
   ```bash
   # Check encryption configuration
   aws s3api get-bucket-encryption --bucket "production-uploads-myapp"
   ```

### Debugging Commands

```bash
# List all buckets
aws s3 ls

# Check bucket configuration
aws s3api get-bucket-versioning --bucket "bucket-name"
aws s3api get-bucket-encryption --bucket "bucket-name"
aws s3api get-public-access-block --bucket "bucket-name"

# Monitor bucket metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name BucketSizeBytes \
  --dimensions Name=BucketName,Value=bucket-name Name=StorageType,Value=StandardStorage \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 86400 \
  --statistics Average
```

## Prerequisites

1. **AWS Account**: Valid AWS account with S3 permissions
2. **IAM Permissions**: Ability to create and manage S3 buckets
3. **Unique Bucket Names**: S3 bucket names must be globally unique
4. **Terraform Providers**: AWS provider configured

## Version Compatibility

| Module Version | Terraform | AWS Provider |
|---------------|-----------|--------------|
| 1.x.x         | >= 1.0    | >= 4.0       |

## Best Practices

1. **Security First**: Use public access block and encryption by default
2. **Naming Convention**: Follow consistent naming patterns
3. **Environment Separation**: Clear separation between environments
4. **Cost Optimization**: Use appropriate versioning and encryption settings
5. **Monitoring**: Implement comprehensive monitoring and alerting
6. **Lifecycle Management**: Configure appropriate lifecycle policies
7. **Backup Strategy**: Implement cross-region replication for critical data
8. **Access Control**: Use least privilege IAM policies

## Contributing

When contributing to this module:
1. Follow established naming conventions
2. Maintain security best practices
3. Test with different bucket configurations
4. Ensure cost optimization considerations
5. Update documentation for new features

## License

This module is provided under the MIT License. See LICENSE file for details.