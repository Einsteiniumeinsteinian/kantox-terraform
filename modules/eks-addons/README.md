# EKS Add-ons Terraform Module

This Terraform module manages AWS EKS (Elastic Kubernetes Service) add-ons for an existing EKS cluster. It provides a flexible way to install and configure multiple EKS managed add-ons with consistent naming conventions and tagging.

## Features

- **Multiple Add-on Support**: Install multiple EKS add-ons in a single module call
- **Flexible Configuration**: Support for custom configuration values and service account role ARNs
- **Consistent Naming**: Automatic naming convention with optional prefixes and suffixes
- **Conflict Resolution**: Configurable conflict resolution for add-on updates
- **Comprehensive Tagging**: Automatic tagging with general tags and resource-specific names
- **Preservation Options**: Control whether add-ons are preserved during destruction

## Usage

### Basic Example

```hcl
module "eks_addons" {
  source = "./modules/eks-addons"

  cluster_name = "my-cluster"
  
  addons = [
    {
      name = "vpc-cni"
    },
    {
      name = "coredns"
    },
    {
      name = "kube-proxy"
    }
  ]

  general_tags = {
    Environment = "production"
    Project     = "myapp"
  }
}
```

### Advanced Example with Custom Configuration

```hcl
module "eks_addons" {
  source = "./modules/eks-addons"

  cluster_name = "my-cluster"
  name_prefix  = "company"
  name_suffix  = "v1"
  
  addons = [
    {
      name                        = "vpc-cni"
      configuration_values        = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET      = "1"
        }
      })
      resolve_conflicts_on_update = "OVERWRITE"
    },
    {
      name                     = "aws-load-balancer-controller"
      service_account_role_arn = "arn:aws:iam::123456789012:role/AmazonEKSLoadBalancerControllerRole"
      preserve                 = true
    },
    {
      name = "amazon-cloudwatch-observability"
      configuration_values = jsonencode({
        agent = {
          config = {
            logs = {
              metrics_collected = {
                kubernetes = {
                  enhanced_container_insights = true
                }
              }
            }
          }
        }
      })
    }
  ]

  general_tags = {
    Environment = "production"
    Project     = "myapp"
    Owner       = "platform-team"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| addons | List of EKS add-ons to install | `list(object)` | n/a | yes |
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| general_tags | Map of general tags to apply to all resources | `map(string)` | n/a | yes |
| name_prefix | Optional name prefix | `string` | `""` | no |
| name_suffix | Optional name suffix | `string` | `""` | no |

### Add-on Object Structure

Each add-on in the `addons` list supports the following attributes:

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| name | Name of the EKS add-on | `string` | yes |
| configuration_values | JSON string of configuration values | `string` | no |
| preserve | Whether to preserve the add-on when the resource is deleted | `bool` | no |
| service_account_role_arn | ARN of the IAM role for the service account | `string` | no |
| resolve_conflicts_on_update | How to resolve conflicts during updates | `string` | no |

### Resolve Conflicts Options

The `resolve_conflicts_on_update` parameter accepts the following values:

- `OVERWRITE` (default): Overwrite existing configuration
- `NONE`: Don't resolve conflicts
- `PRESERVE`: Preserve existing configuration

## Outputs

| Name | Description |
|------|-------------|
| eks_addons | Map of EKS managed add-ons created with their IDs |

## Common EKS Add-ons

Here are some commonly used EKS add-ons you can install with this module:

### Core Add-ons

- `vpc-cni`: Amazon VPC CNI plugin for Kubernetes
- `coredns`: CoreDNS for cluster DNS resolution
- `kube-proxy`: Kubernetes network proxy
- `aws-ebs-csi-driver`: Amazon EBS CSI driver

### Additional Add-ons

- `aws-load-balancer-controller`: AWS Load Balancer Controller
- `amazon-cloudwatch-observability`: CloudWatch Container Insights
- `adot`: AWS Distro for OpenTelemetry
- `eks-pod-identity-agent`: EKS Pod Identity Agent
- `snapshot-controller`: Volume snapshot controller

## Naming Convention

The module automatically generates resource names using the following pattern:

```
[name_prefix-][Environment]-[Project]-[cluster_name][-name_suffix]-addon-[addon_name]
```

Example: `company-production-myapp-my-cluster-v1-addon-vpc-cni`

## Prerequisites

- Existing EKS cluster
- Appropriate IAM permissions to manage EKS add-ons
- For some add-ons, additional IAM roles may be required (e.g., AWS Load Balancer Controller)

## IAM Considerations

Some EKS add-ons require specific IAM roles or service account configurations:

1. **AWS Load Balancer Controller**: Requires an IAM role with appropriate permissions
2. **EBS CSI Driver**: May require additional permissions for volume operations
3. **CloudWatch Observability**: Requires permissions for CloudWatch and X-Ray

Ensure the necessary IAM roles are created before installing add-ons that require them.

## Examples

### Installing Core Add-ons Only

```hcl
module "core_addons" {
  source = "./modules/eks-addons"

  cluster_name = var.cluster_name
  
  addons = [
    { name = "vpc-cni" },
    { name = "coredns" },
    { name = "kube-proxy" },
    { name = "aws-ebs-csi-driver" }
  ]

  general_tags = var.common_tags
}
```

### Installing Add-ons with Preservation

```hcl
module "critical_addons" {
  source = "./modules/eks-addons"

  cluster_name = var.cluster_name
  
  addons = [
    {
      name     = "vpc-cni"
      preserve = true
    },
    {
      name     = "coredns"
      preserve = true
    }
  ]

  general_tags = var.common_tags
}
```

## Version Compatibility

This module is compatible with:

- Terraform >= 1.0
- AWS Provider >= 4.0
- EKS clusters running Kubernetes 1.21+

## Contributing

When contributing to this module, please ensure:

1. All variables are properly documented
2. Examples are provided for complex configurations
3. Output descriptions are clear and helpful
4. Code follows Terraform best practices

## License

This module is provided under the MIT License. See LICENSE file for details.
