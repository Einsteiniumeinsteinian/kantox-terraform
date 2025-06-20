# AWS Parameter Store Terraform Module

This Terraform module creates and manages AWS Systems Manager Parameter Store parameters with a standardized naming convention and comprehensive tagging strategy. It provides a centralized, secure, and organized approach to configuration management for applications and infrastructure.

## Features

- **Centralized Configuration**: Manage all application and infrastructure parameters in one place
- **Standardized Naming**: Consistent parameter naming convention with project and environment prefixes
- **Multiple Parameter Types**: Support for String, SecureString, and StringList parameter types
- **Comprehensive Tagging**: Automatic tagging with project, environment, and parameter metadata
- **Batch Management**: Create multiple parameters efficiently with a single module call
- **Environment Isolation**: Clear separation of parameters by environment
- **Integration Ready**: Designed for seamless integration with application deployment workflows

## Parameter Organization

The module organizes parameters using a hierarchical naming structure:

```path
/{Project}/{Environment}/{parameter-key}
```

**Examples:**

- `/myapp/production/database/host`
- `/myapp/production/api/jwt-secret`
- `/myapp/staging/redis/password`
- `/mycompany/development/feature-flags/new-ui-enabled`

## Usage

### Basic Example

```hcl
module "parameter_store" {
  source = "./terraform/modules/parameter-store"

  parameters = {
    "database/host" = {
      type        = "String"
      value       = "myapp-prod-db.cluster-xyz.us-west-2.rds.amazonaws.com"
      description = "Production database hostname"
    }
    "database/port" = {
      type        = "String"
      value       = "5432"
      description = "Production database port"
    }
    "api/jwt-secret" = {
      type        = "SecureString"
      value       = "super-secret-jwt-key-here"
      description = "JWT signing secret for API authentication"
    }
  }

  general_tags = {
    Project     = "myapp"
    Environment = "production"
    Owner       = "platform-team"
    Team        = "backend"
    ManagedBy   = "terraform"
  }
}
```

### Complete Application Configuration

```hcl
module "app_config_production" {
  source = "./terraform/modules/parameter-store"

  parameters = {
    # Database Configuration
    "database/host" = {
      type        = "String"
      value       = module.rds.cluster_endpoint
      description = "RDS cluster endpoint for application database"
    }
    "database/port" = {
      type        = "String"
      value       = "5432"
      description = "Database port number"
    }
    "database/name" = {
      type        = "String"
      value       = "myapp_production"
      description = "Production database name"
    }
    "database/username" = {
      type        = "String"
      value       = "myapp_user"
      description = "Database username for application"
    }
    "database/password" = {
      type        = "SecureString"
      value       = random_password.db_password.result
      description = "Database password for application user"
    }

  general_tags = {
    Project     = "myapp"
    Environment = "production"
    Owner       = "platform-team"
    Team        = "backend"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}
```

## Inputs

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| parameters | Parameters to store in AWS Parameter Store | `map(object)` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| general_tags | Tags to apply to resources | `map(string)` | `{}` |

### Parameters Object Structure

```hcl
parameters = {
  "parameter-key" = {
    type        = string  # Parameter type: "String", "SecureString", or "StringList"
    value       = string  # Parameter value
    description = string  # Parameter description
  }
}
```

### Parameter Types

| Type | Description | Use Cases | Encryption |
|------|-------------|-----------|------------|
| `String` | Plain text parameter | Configuration values, URLs, non-sensitive data | No |
| `SecureString` | Encrypted parameter | Passwords, API keys, secrets | Yes (KMS) |
| `StringList` | Comma-separated list | Multiple values, arrays, lists | No |

## Outputs

| Name | Description |
|------|-------------|
| parameters | Complete parameter information with names, ARNs, and types |
| parameter_names | List of all parameter names |
| parameter_arns | List of all parameter ARNs |

### Output Structures

#### Parameters Output

```hcl
parameters = {
  "database/host" = {
    name = "/myapp/production/database/host"
    arn  = "arn:aws:ssm:us-west-2:123456789012:parameter/myapp/production/database/host"
    type = "String"
  }
  "api/jwt-secret" = {
    name = "/myapp/production/api/jwt-secret"
    arn  = "arn:aws:ssm:us-west-2:123456789012:parameter/myapp/production/api/jwt-secret"
    type = "SecureString"
  }
}
```

## Parameter Naming Conventions

### Recommended Naming Structure

```path
/{Project}/{Environment}/{Category}/{Parameter}
```

## Security Best Practices

### Parameter Types and Encryption

1. **Use SecureString for Sensitive Data**

   ```hcl
   "database/password" = {
     type        = "SecureString"  # Automatically encrypted with KMS
     value       = random_password.db_password.result
     description = "Database password"
   }
   ```

2. **Use String for Non-Sensitive Configuration**

   ```hcl
   "database/host" = {
     type        = "String"  # Plain text, no encryption needed
     value       = "myapp-db.cluster-xyz.amazonaws.com"
     description = "Database hostname"
   }
   ```

3. **Use StringList for Multiple Values**

   ```hcl
   "api/cors-origins" = {
     type        = "StringList"  # Comma-separated values
     value       = "https://app.com,https://admin.app.com"
     description = "Allowed CORS origins"
   }
   ```

### IAM Permissions

Ensure applications have appropriate IAM permissions to access parameters:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": [
        "arn:aws:ssm:*:*:parameter/myapp/production/*"
      ]
    }
  ]
}
```

### Parameter Access Patterns

1. **Read-Only Access for Applications**
2. **Write Access for CI/CD Pipelines**
3. **Admin Access for Infrastructure Teams**

## Application Integration

### Environment Variables from Parameters

```bash
#!/bin/bash
# Script to load parameters as environment variables

export DB_HOST=$(aws ssm get-parameter --name "/myapp/production/database/host" --query 'Parameter.Value' --output text)
export DB_PASSWORD=$(aws ssm get-parameter --name "/myapp/production/database/password" --with-decryption --query 'Parameter.Value' --output text)
export JWT_SECRET=$(aws ssm get-parameter --name "/myapp/production/api/jwt-secret" --with-decryption --query 'Parameter.Value' --output text)
```

### Kubernetes Integration

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: production
type: Opaque
data:
  DB_PASSWORD: # Retrieved from Parameter Store
  JWT_SECRET: # Retrieved from Parameter Store
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  DB_HOST: # Retrieved from Parameter Store
  DB_PORT: # Retrieved from Parameter Store
```

### Docker Compose Integration

```yaml
version: '3.8'
services:
  web:
    image: myapp:latest
    environment:
      - DB_HOST=${DB_HOST}
      - DB_PASSWORD=${DB_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
    env_file:
      - .env.production  # Contains parameters from Parameter Store
```

#### Node.js

```javascript
const AWS = require('aws-sdk');
const ssm = new AWS.SSM();

async function getParameter(name, decrypt = false) {
  const params = {
    Name: `/myapp/production/${name}`,
    WithDecryption: decrypt
  };
  
  const result = await ssm.getParameter(params).promise();
  return result.Parameter.Value;
}

// Usage
const dbHost = await getParameter('database/host');
const dbPassword = await getParameter('database/password', true);
const jwtSecret = await getParameter('api/jwt-secret', true);
```

## Monitoring and Auditing

### CloudTrail Integration

Monitor parameter access and modifications:

```hcl
resource "aws_cloudtrail" "parameter_audit" {
  name           = "${var.project}-parameter-audit"
  s3_bucket_name = aws_s3_bucket.cloudtrail.bucket

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    
    data_resource {
      type   = "AWS::SSM::Parameter"
      values = ["arn:aws:ssm:*:*:parameter/${var.project}/*"]
    }
  }

  tags = var.common_tags
}
```

### CloudWatch Metrics

```hcl
resource "aws_cloudwatch_metric_alarm" "parameter_access_failures" {
  alarm_name          = "${var.project}-parameter-access-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorCount"
  namespace           = "AWS/SSM"
  period              = "120"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors SSM parameter access failures"
  
  dimensions = {
    ParameterName = "/${var.project}/*"
  }
}
```

## Troubleshooting

### Common Issues

1. **Parameter Not Found**

   ```bash
   # Check parameter exists
   aws ssm get-parameter --name "/myapp/production/database/host"
   
   # List parameters by path
   aws ssm get-parameters-by-path --path "/myapp/production" --recursive
   ```

2. **Access Denied**

   ```bash
   # Check IAM permissions
   aws iam simulate-principal-policy \
     --policy-source-arn "arn:aws:iam::123456789012:role/MyRole" \
     --action-names "ssm:GetParameter" \
     --resource-arns "arn:aws:ssm:us-west-2:123456789012:parameter/myapp/production/database/host"
   ```

3. **Decryption Failures**

   ```bash
   # Check KMS permissions
   aws ssm get-parameter --name "/myapp/production/api/jwt-secret" --with-decryption
   ```

### Debugging Commands

```bash
# List all parameters for a project
aws ssm describe-parameters --filters "Key=Name,Values=/myapp"

# Get parameter with metadata
aws ssm get-parameter --name "/myapp/production/database/host" --query 'Parameter'

# Get multiple parameters
aws ssm get-parameters --names "/myapp/production/database/host" "/myapp/production/database/port"

# Get parameters by path
aws ssm get-parameters-by-path --path "/myapp/production" --recursive --with-decryption

# Check parameter history
aws ssm get-parameter-history --name "/myapp/production/database/host"
```

## Cost Optimization

### Parameter Pricing

- **Standard Parameters**: $0.05 per 10,000 API calls
- **Advanced Parameters**: $0.05 per 10,000 API calls + $0.05 per parameter per month
- **SecureString**: Additional KMS costs for encryption/decryption

### Cost Optimization Strategies

1. **Batch Parameter Retrieval**

   ```bash
   # Get multiple parameters in one call
   aws ssm get-parameters --names "/myapp/production/database/host" "/myapp/production/database/port"
   ```

2. **Use Standard Parameters When Possible**
   - Standard parameters are free for storage
   - Advanced parameters have monthly charges

3. **Cache Parameters in Applications**

   ```python
   # Cache parameters to reduce API calls
   import time
   
   parameter_cache = {}
   cache_ttl = 300  # 5 minutes
   
   def get_cached_parameter(name):
       if name in parameter_cache:
           value, timestamp = parameter_cache[name]
           if time.time() - timestamp < cache_ttl:
               return value
       
       value = get_parameter(name)
       parameter_cache[name] = (value, time.time())
       return value
   ```

## Prerequisites

1. **AWS Account**: Valid AWS account with SSM permissions
2. **IAM Permissions**: Ability to create and manage SSM parameters
3. **KMS Key**: Default or custom KMS key for SecureString parameters
4. **Terraform Providers**: AWS provider configured

## Version Compatibility

| Module Version | Terraform | AWS Provider |
|---------------|-----------|--------------|
| 1.x.x         | >= 1.0    | >= 4.0       |

## Best Practices

1. **Naming Convention**: Use consistent, hierarchical naming
2. **Environment Separation**: Separate parameters by environment
3. **Type Selection**: Use appropriate parameter types for security
4. **Documentation**: Include meaningful descriptions
5. **Access Control**: Implement least privilege access
6. **Monitoring**: Track parameter access and modifications
7. **Backup**: Regular parameter backups for disaster recovery
8. **Caching**: Cache parameters in applications to reduce costs

## Contributing

When contributing to this module:

1. Follow the established naming conventions
2. Add comprehensive parameter descriptions
3. Test with different parameter types
4. Ensure proper tagging implementation
5. Update documentation for new features

## License

This module is provided under the MIT License. See LICENSE file for details.
