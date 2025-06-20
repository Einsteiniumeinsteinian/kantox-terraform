# EKS Cluster Terraform Module

This Terraform module creates and manages an AWS EKS (Elastic Kubernetes Service) cluster with all necessary supporting resources. It provides a complete, production-ready EKS cluster deployment with security best practices, monitoring capabilities, and flexible configuration options.

## Features

- **Complete EKS Cluster Setup**: Creates EKS cluster with all required IAM roles and policies
- **Security Best Practices**: Includes OIDC provider, KMS encryption, and secure endpoint configuration
- **Monitoring & Logging**: CloudWatch log group integration with configurable log types and retention
- **Flexible Networking**: Configurable VPC, subnet, and security group settings
- **Encryption Support**: Optional KMS encryption for cluster secrets with automatic key rotation
- **IRSA Ready**: Automatic OIDC provider setup for IAM Roles for Service Accounts
- **Consistent Naming**: Automatic naming convention with optional prefixes and suffixes
- **Comprehensive Tagging**: Automatic tagging with general tags and resource-specific names

## Architecture

The module creates the following resources:

1. **EKS Cluster**: The main Kubernetes cluster with specified version
2. **IAM Role & Policies**: Service role for the EKS cluster with required AWS managed policies
   - `AmazonEKSClusterPolicy`
   - `AmazonEKSVPCResourceController`
3. **KMS Key & Alias**: (Optional) For encrypting Kubernetes secrets with automatic rotation
4. **CloudWatch Log Group**: (Optional) For cluster logging with configurable retention
5. **OIDC Identity Provider**: For pod-level IAM roles (IRSA - IAM Roles for Service Accounts)

## Usage

### Basic Example

```hcl
module "eks_cluster" {
  source = "./modules/eks-cluster"

  cluster = {
    name                      = "my-app"
    version                   = "1.29"
    enable_encryption         = false
    enable_cluster_log_types  = []
    log_retention_in_days     = 7
    kms_key_deletion_window   = 7
  }

  network = {
    vpc_id                     = "vpc-12345678"
    subnet_ids                 = ["subnet-12345", "subnet-67890"]
    endpoint_private_access    = true
    endpoint_public_access     = true
    public_access_cidrs        = ["0.0.0.0/0"]
    security_groups_ids        = ["sg-12345678"]
  }

  general_tags = {
    Environment = "production"
    Project     = "myapp"
    Owner       = "platform-team"
    Team        = "devops"
  }
}
```

### Advanced Example with Full Configuration

```hcl
module "eks_cluster" {
  source = "./modules/eks-cluster"

  name_prefix = "company"
  name_suffix = "v1"

  cluster = {
    name                      = "main"
    version                   = "1.29"
    enable_encryption         = true
    kms_key_deletion_window   = 7
    enable_cluster_log_types  = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
    log_retention_in_days     = 14
  }

  network = {
    vpc_id                     = data.aws_vpc.main.id
    subnet_ids                 = data.aws_subnets.private.ids
    endpoint_private_access    = true
    endpoint_public_access     = false
    public_access_cidrs        = []
    security_groups_ids        = [aws_security_group.eks_cluster.id]
  }

  general_tags = {
    Environment = "production"
    Project     = "myapp"
    Owner       = "platform-team"
    Team        = "devops"
    ManagedBy   = "terraform"
  }

  optional_tags = {
    launch_template = {
      "CustomTag" = "CustomValue"
    }
  }
}
```

### Private Cluster Example

```hcl
module "eks_private_cluster" {
  source = "./modules/eks-cluster"

  cluster = {
    name                      = "private-cluster"
    version                   = "1.29"
    enable_encryption         = true
    kms_key_deletion_window   = 10
    enable_cluster_log_types  = ["api", "audit"]
    log_retention_in_days     = 30
  }

  network = {
    vpc_id                     = var.vpc_id
    subnet_ids                 = var.private_subnet_ids
    endpoint_private_access    = true
    endpoint_public_access     = false
    public_access_cidrs        = []
    security_groups_ids        = [var.cluster_security_group_id]
  }

  general_tags = var.common_tags
}
```

## Inputs

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| cluster | Cluster configuration values | `object` |
| network | Network-related configuration | `object` |
| general_tags | General tags including Environment and Project | `object` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| name_prefix | Optional prefix for all name tags | `string` | `""` |
| name_suffix | Optional suffix for all name tags | `string` | `""` |
| optional_tags | Optional tags per resource type | `object` | `{}` |

### Cluster Object Structure

```hcl
cluster = {
  name                      = string  # Name of the cluster
  version                   = string  # Kubernetes version (e.g., "1.29")
  enable_encryption         = bool    # Enable KMS encryption for secrets
  enable_cluster_log_types  = list(string)  # List of log types to enable
  log_retention_in_days     = number  # CloudWatch log retention period
  kms_key_deletion_window   = number  # KMS key deletion window (7-30 days)
}
```

### Network Object Structure

```hcl
network = {
  vpc_id                     = string        # VPC ID where cluster will be created
  subnet_ids                 = list(string) # List of subnet IDs for the cluster
  endpoint_private_access    = bool          # Enable private API endpoint access
  endpoint_public_access     = bool          # Enable public API endpoint access
  public_access_cidrs        = list(string) # CIDR blocks for public access
  security_groups_ids        = list(string) # Additional security groups
}
```

### General Tags Object Structure

```hcl
general_tags = {
  Environment = string                # Environment (e.g., "production", "staging")
  Owner       = string                # Owner of the resources
  Project     = string                # Project name
  Team        = string                # Team responsible
  ManagedBy   = optional(string, "terraform")  # Management tool
}
```

### Cluster Log Types

Available log types for `enable_cluster_log_types`:

- `api`: API server logs
- `audit`: Audit logs
- `authenticator`: Authenticator logs
- `controllerManager`: Controller manager logs
- `scheduler`: Scheduler logs

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | EKS cluster ID |
| cluster_arn | EKS cluster ARN |
| cluster_name | EKS cluster name |
| cluster_endpoint | EKS cluster API endpoint |
| cluster_version | EKS cluster Kubernetes version |
| cluster_platform_version | EKS cluster platform version |
| cluster_certificate_authority_data | Base64 encoded certificate authority data |
| cluster_security_group_id | Security group ID attached to the EKS cluster |
| cluster_role_arn | EKS cluster IAM role ARN |
| oidc_provider_arn | OIDC provider ARN for IRSA |
| oidc_provider_url | OIDC provider URL (without https://) |
| oidc_provider_url_https | OIDC provider URL (with https://) |
| kms_key_arn | KMS key ARN used for encryption (if enabled) |
| kms_key_id | KMS key ID used for encryption (if enabled) |

## Naming Convention

The module automatically generates resource names using the following pattern:

```bash
[name_prefix-][Environment]-[Project]-[cluster.name]-cluster[-name_suffix]
```

**Example**: `company-production-myapp-main-cluster-v1`

## Security Considerations

### Network Security

- **Private Endpoints**: Set `endpoint_public_access = false` for maximum security
- **CIDR Restrictions**: Use specific CIDR blocks in `public_access_cidrs` instead of `0.0.0.0/0`
- **Security Groups**: Attach appropriate security groups to control network access

### Encryption

- **Secrets Encryption**: Enable `enable_encryption = true` to encrypt Kubernetes secrets at rest
- **KMS Key Management**: The module creates a dedicated KMS key with automatic rotation
- **Key Deletion**: Configure `kms_key_deletion_window` based on your security requirements

### IAM and RBAC

- **OIDC Provider**: Automatically configured for IAM Roles for Service Accounts (IRSA)
- **Least Privilege**: Cluster role uses only required AWS managed policies
- **Service Account Integration**: Ready for pod-level IAM roles

## Monitoring and Logging

### CloudWatch Integration

- **Cluster Logs**: Enable specific log types based on your monitoring needs
- **Log Retention**: Configure retention period to balance cost and compliance
- **Log Analysis**: Use CloudWatch Insights for log analysis

### Recommended Log Types

- **Production**: `["api", "audit", "authenticator"]`
- **Development**: `["api"]`
- **Compliance**: `["api", "audit", "authenticator", "controllerManager", "scheduler"]`

## Prerequisites

1. **AWS Credentials**: Appropriate IAM permissions to create EKS resources
2. **VPC Setup**: Existing VPC with subnets configured for EKS
3. **Security Groups**: Appropriate security groups for cluster communication
4. **Terraform Version**: >= 1.0
5. **AWS Provider**: >= 4.0

### Required IAM Permissions

The deploying user/role needs permissions for:

- EKS cluster management
- IAM role and policy management
- KMS key management (if encryption enabled)
- CloudWatch log group management
- OIDC provider management

## Post-Deployment Steps

1. **Configure kubectl**: Update your kubeconfig to connect to the cluster

   ```bash
   aws eks update-kubeconfig --region <region> --name <cluster-name>
   ```

2. **Install Node Groups**: Use the EKS node group module or Fargate profiles

3. **Install Add-ons**: Use the EKS add-ons module for essential cluster components

4. **Configure RBAC**: Set up Kubernetes RBAC for user and service account access

## Troubleshooting

### Common Issues

1. **Cluster Creation Timeout**
   - Check subnet configurations and routing
   - Verify security group rules
   - Ensure IAM permissions are correct

2. **OIDC Provider Issues**
   - Verify TLS certificate retrieval
   - Check cluster endpoint accessibility

3. **Encryption Problems**
   - Confirm KMS key permissions
   - Verify encryption is supported in the region

### Debugging Tips

- Enable all log types temporarily for troubleshooting
- Check CloudWatch logs for detailed error messages
- Verify network connectivity between subnets
- Confirm security group rules allow required traffic

## Version Compatibility

| Module Version | Terraform | AWS Provider | Kubernetes |
|---------------|-----------|--------------|------------|
| 1.x.x         | >= 1.0    | >= 4.0       | 1.21+      |

## Best Practices

1. **Use Private Subnets**: Deploy cluster in private subnets when possible
2. **Enable Encryption**: Always enable encryption for production clusters
3. **Restrict Public Access**: Limit public access CIDRs to specific IP ranges
4. **Monitor Logs**: Enable appropriate log types for your security requirements
5. **Regular Updates**: Keep cluster version updated with latest patches
6. **Backup Strategy**: Implement backup strategy for persistent volumes
7. **Resource Tagging**: Use comprehensive tagging for cost allocation and management

## Contributing

When contributing to this module:

1. Follow Terraform best practices and style guide
2. Update documentation for any new variables or outputs
3. Test changes in multiple environments
4. Ensure backward compatibility
5. Update version compatibility matrix

## License

This module is provided under the MIT License. See LICENSE file for details.
