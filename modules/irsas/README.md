# IAM Module for EKS Service Accounts

This Terraform module creates IAM roles and policies for Kubernetes service accounts using IAM Roles for Service Accounts (IRSA) and GitHub Actions OIDC integration. It provides secure, least-privilege access for applications running in EKS clusters and CI/CD workflows. This is application specific module.

## Features

- **IRSA Integration**: Complete setup for IAM Roles for Service Accounts with EKS OIDC provider
- **Service Account Roles**: Pre-configured roles for main API and auxiliary services
- **GitHub Actions OIDC**: Secure CI/CD integration without long-lived credentials
- **Least Privilege**: Minimal required permissions for each service
- **Parameter Store Access**: Secure configuration management through AWS Systems Manager
- **ECR Integration**: Container registry access for GitHub Actions
- **S3 Permissions**: Configurable S3 bucket access for services
- **Comprehensive Tagging**: Consistent resource tagging strategy

## Architecture

The module creates the following IAM resources:

### Service Account Roles

1. **Main API Role**: For main application service account
   - S3 bucket listing permissions
   - SSM Parameter Store access
   - Namespace: `main-api`
   - Service Account: `main-api-service-account`

2. **Auxiliary Service Role**: For supporting services
   - S3 bucket listing and read permissions
   - SSM Parameter Store access
   - Namespace: `auxiliary-service`
   - Service Account: `auxiliary-service-account`

### GitHub Actions Integration

1. **GitHub Actions Role**: For CI/CD workflows
   - ECR repository access (pull/push)
   - EKS cluster describe permissions
   - SSM Parameter Store access for versioning

2. **GitHub OIDC Provider**: Enables secure authentication from GitHub Actions

## Usage

### Basic Example

```hcl
module "iam_roles" {
  source = "./terraform/modules/iam"

  cluster_name        = "my-cluster"
  oidc_provider_arn   = module.eks_cluster.oidc_provider_arn
  oidc_provider_url   = module.eks_cluster.oidc_provider_url
  region              = "us-west-2"
  github_repo         = "myorg/myproject"
  s3_bucket_arns      = ["arn:aws:s3:::my-app-bucket"]

  general_tags = {
    Environment = "production"
    Project     = "myapp"
    Owner       = "platform-team"
    Team        = "devops"
    ManagedBy   = "terraform"
  }
}
```

### Complete EKS Integration Example

```hcl
# EKS Cluster
module "eks_cluster" {
  source = "./modules/eks-cluster"
  # ... cluster configuration
}

# IAM Roles for Service Accounts
module "iam_roles" {
  source = "./terraform/modules/iam"

  cluster_name        = module.eks_cluster.cluster_name
  oidc_provider_arn   = module.eks_cluster.oidc_provider_arn
  oidc_provider_url   = module.eks_cluster.oidc_provider_url
  region              = var.aws_region
  github_repo         = var.github_repository
  
  s3_bucket_arns = [
    module.app_bucket.bucket_arn,
    module.backup_bucket.bucket_arn
  ]

  general_tags = var.common_tags

  depends_on = [module.eks_cluster]
}
```

### Multi-Environment Setup

```hcl
module "iam_roles_staging" {
  source = "./terraform/modules/iam"

  cluster_name        = "${var.project_name}-staging-cluster"
  oidc_provider_arn   = module.eks_cluster_staging.oidc_provider_arn
  oidc_provider_url   = module.eks_cluster_staging.oidc_provider_url
  region              = var.aws_region
  github_repo         = "myorg/myproject"
  s3_bucket_arns      = [module.staging_bucket.bucket_arn]

  general_tags = merge(var.common_tags, {
    Environment = "staging"
  })
}

module "iam_roles_production" {
  source = "./terraform/modules/iam"

  cluster_name        = "${var.project_name}-production-cluster"
  oidc_provider_arn   = module.eks_cluster_production.oidc_provider_arn
  oidc_provider_url   = module.eks_cluster_production.oidc_provider_url
  region              = var.aws_region
  github_repo         = "myorg/myproject"
  s3_bucket_arns      = [
    module.production_bucket.bucket_arn,
    module.production_backup_bucket.bucket_arn
  ]

  general_tags = merge(var.common_tags, {
    Environment = "production"
  })
}
```

## Inputs

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| general_tags | Global required tags for all resources | `object` |
| cluster_name | EKS cluster name | `string` |
| oidc_provider_arn | OIDC provider ARN from EKS cluster | `string` |
| oidc_provider_url | OIDC provider URL from EKS cluster | `string` |
| region | AWS region | `string` |
| github_repo | GitHub repository in format owner/repo | `string` |
| s3_bucket_arns | List of S3 bucket ARNs for access | `list(string)` |

### General Tags Object Structure

```hcl
general_tags = {
  Environment = string                          # Environment (e.g., "production", "staging")
  Owner       = string                          # Owner of the resources
  Project     = string                          # Project name
  Team        = string                          # Team responsible
  ManagedBy   = optional(string, "terraform")   # Management tool
}
```

## Outputs

| Name | Description |
|------|-------------|
| service_account_roles | IAM roles for service accounts with ARN and name |
| github_oidc_provider_arn | GitHub OIDC provider ARN |

### Service Account Roles Output Structure

```hcl
service_account_roles = {
  auxiliary_service = {
    arn  = "arn:aws:iam::123456789012:role/myapp-production-auxiliary-service-role"
    name = "myapp-production-auxiliary-service-role"
  }
  github_actions = {
    arn  = "arn:aws:iam::123456789012:role/myapp-production-github-actions-role"
    name = "myapp-production-github-actions-role"
  }
}
```

## Service Account Details

### Main API Service Account

**Kubernetes Configuration:**

- **Namespace**: `main-api`
- **Service Account**: `main-api-service-account`

**Permissions:**

- List all S3 buckets
- Get S3 bucket locations
- Read SSM parameters under `/{Project}/{Environment}/*`

**Example Kubernetes Service Account:**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: main-api-service-account
  namespace: main-api
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/PROJECT-ENV-main-api-role
```

### Auxiliary Service Account

**Kubernetes Configuration:**

- **Namespace**: `auxiliary-service`
- **Service Account**: `auxiliary-service-account`

**Permissions:**

- List all S3 buckets and specific bucket contents
- Read SSM parameters under `/{Project}/{Environment}/*`
- Access to specified S3 bucket ARNs (all)

**Example Kubernetes Service Account:**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: auxiliary-service-account
  namespace: auxiliary-service
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/PROJECT-ENV-auxiliary-service-role
```

### OIDC Provider Configuration

The module creates a GitHub OIDC provider with:

- **URL**: `https://token.actions.githubusercontent.com`
- **Audience**: `sts.amazonaws.com`
- **Thumbprints**: Latest GitHub Actions thumbprints

### GitHub Actions Role Permissions

- **ECR Access**: Full ECR repository operations (push/pull images)
- **EKS Access**: Describe cluster permissions
- **SSM Access**: Parameter management for version tracking

### GitHub Actions Workflow Example

```yaml
name: Deploy to EKS
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    
    steps:
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
        aws-region: us-west-2
    
    - name: Login to Amazon ECR
      uses: aws-actions/amazon-ecr-login@v2
    
    - name: Build and push Docker image
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$GITHUB_SHA .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$GITHUB_SHA
    
    - name: Update Kubernetes deployment
      run: |
        aws eks update-kubeconfig --name ${{ env.CLUSTER_NAME }}
        kubectl set image deployment/main-api main-api=$ECR_REGISTRY/$ECR_REPOSITORY:$GITHUB_SHA
```

## Parameter Store Structure

The module configures access to SSM parameters following this hierarchy:

```bash
/{Project}/{Environment}/
├── database/
│   ├── host
│   ├── port
│   └── name
├── api/
│   ├── secret-key
│   └── jwt-secret
├── redis/
│   ├── host
│   └── port
└── version/
    ├── main-api
    └── auxiliary-service
```

### Parameter Access Examples

**Main API Service:**

- Read: `/{Project}/{Environment}/*`
- Examples: `/myapp/production/database/host`, `/myapp/production/api/secret-key`

**GitHub Actions:**

- Read/Write: `/{Project}/{Environment}/version/*`
- Examples: `/myapp/production/version/main-api`, `/myapp/production/version/auxiliary-service`

## Security Best Practices

### OIDC Trust Relationships

The module implements secure OIDC trust relationships with:

1. **Audience Validation**: Ensures tokens are intended for AWS STS
2. **Subject Validation**: Restricts access to specific namespaces and service accounts
3. **Repository Validation**: GitHub Actions access limited to specified repository

### Least Privilege Access

Each role includes only the minimum required permissions:

- **Service Accounts**: Access only to necessary AWS services and resources
- **GitHub Actions**: Limited to deployment-related operations
- **Parameter Store**: Scoped to project and environment specific parameters

### Trust Policy Examples

**Service Account Trust Policy:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT:oidc-provider/oidc.eks.REGION.amazonaws.com/id/OIDCID"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.REGION.amazonaws.com/id/OIDCID:sub": "system:serviceaccount:main-api:main-api-service-account",
          "oidc.eks.REGION.amazonaws.com/id/OIDCID:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

## Monitoring and Auditing

### CloudTrail Integration

Monitor role usage through CloudTrail events:

- `AssumeRoleWithWebIdentity` calls
- Parameter Store access (`GetParameter`, `PutParameter`)
- ECR operations (`GetAuthorizationToken`, `PutImage`)

### Recommended Monitoring

```hcl
# CloudWatch Log Group for monitoring
resource "aws_cloudwatch_log_group" "iam_audit" {
  name              = "/aws/iam/${var.general_tags.Project}-${var.general_tags.Environment}"
  retention_in_days = 30
  
  tags = var.general_tags
}

# CloudTrail for API calls
resource "aws_cloudtrail" "iam_audit" {
  name           = "${var.general_tags.Project}-${var.general_tags.Environment}-iam-audit"
  s3_bucket_name = aws_s3_bucket.cloudtrail.bucket
  
  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    data_resource {
      type   = "AWS::SSM::Parameter"
      values = ["arn:aws:ssm:*:*:parameter/${var.general_tags.Project}/${var.general_tags.Environment}/*"]
    }
  }
}
```

## Troubleshooting

### Common Issues

1. **Service Account Not Assuming Role**

   ```bash
   # Check OIDC provider configuration
   aws iam get-openid-connect-provider --open-id-connect-provider-arn <oidc-arn>
   
   # Verify service account annotations
   kubectl describe serviceaccount -n main-api main-api-service-account
   ```

2. **GitHub Actions Authentication Failing**

   ```bash
   # Verify OIDC provider thumbprints
   aws iam get-openid-connect-provider --open-id-connect-provider-arn <github-oidc-arn>
   
   # Check repository format in trust policy
   aws iam get-role --role-name <github-actions-role-name>
   ```

3. **Parameter Store Access Denied**

   ```bash
   # Test parameter access
   aws ssm get-parameter --name "/{Project}/{Environment}/test"
   
   # Check parameter path permissions
   aws iam simulate-principal-policy --policy-source-arn <role-arn> --action-names ssm:GetParameter --resource-arns <parameter-arn>
   ```

### Debugging Commands

```bash
# Check role trust relationships
aws iam get-role --role-name <role-name> --query 'Role.AssumeRolePolicyDocument'

# List attached policies
aws iam list-attached-role-policies --role-name <role-name>

# Test role assumptions (from pod)
kubectl exec -it <pod-name> -n <namespace> -- aws sts get-caller-identity

# Check GitHub Actions token
curl -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
     "$ACTIONS_ID_TOKEN_REQUEST_URL" | jq .
```

## Prerequisites

1. **EKS Cluster**: Existing EKS cluster with OIDC provider enabled
2. **OIDC Provider**: EKS OIDC provider ARN and URL
3. **S3 Buckets**: S3 buckets that services need to access
4. **GitHub Repository**: Repository for GitHub Actions integration
5. **AWS Permissions**: IAM permissions to create roles and policies

## Version Compatibility

| Module Version | Terraform | AWS Provider | Kubernetes |
|---------------|-----------|--------------|------------|
| 1.x.x         | >= 1.0    | >= 4.0       | 1.21+      |

## Best Practices

1. **Namespace Isolation**: Use separate namespaces for different services
2. **Service Account Names**: Use descriptive, consistent naming conventions
3. **Parameter Organization**: Organize parameters in a clear hierarchy
4. **Role Rotation**: Regularly review and update role permissions
5. **Monitoring**: Implement comprehensive logging and monitoring
6. **Testing**: Test role assumptions in different environments
7. **Documentation**: Document service account requirements clearly

## Contributing

When contributing to this module:

1. Follow security best practices for IAM policies
2. Test OIDC integration thoroughly
3. Update documentation for new services
4. Ensure backward compatibility
5. Validate against multiple AWS regions

## License

This module is provided under the MIT License. See LICENSE file for details.
