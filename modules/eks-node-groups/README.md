# EKS Node Groups Terraform Module

This Terraform module creates and manages AWS EKS (Elastic Kubernetes Service) node groups with customizable launch templates. It provides a flexible, production-ready solution for deploying worker nodes with advanced configuration options, security best practices, and comprehensive monitoring capabilities.

## Features

- **Multiple Node Groups**: Support for creating multiple node groups with different configurations
- **Custom Launch Templates**: Advanced launch template configuration with user data, monitoring, and security settings
- **Flexible Instance Types**: Support for multiple instance types per node group
- **Spot and On-Demand**: Mixed capacity types for cost optimization
- **Advanced Storage**: Configurable EBS volumes with encryption, IOPS, and throughput settings
- **Security Hardening**: IMDSv2 enforcement, encrypted volumes, and SSM integration
- **Kubernetes Integration**: Support for labels, taints, and remote access configuration
- **Auto Scaling**: Configurable scaling policies with update strategies
- **Comprehensive Monitoring**: CloudWatch monitoring and detailed instance tagging

## Architecture

The module creates the following resources for each node group:

1. **IAM Role & Policies**: Worker node role with required AWS managed policies
2. **Launch Template**: Custom launch template with advanced configuration
3. **EKS Node Group**: Managed node group with auto-scaling capabilities
4. **AMI Selection**: Automatic selection of latest EKS-optimized AMI

### IAM Policies Attached

- `AmazonEKSWorkerNodePolicy`
- `AmazonEKS_CNI_Policy`
- `AmazonEC2ContainerRegistryReadOnly`
- `AmazonSSMManagedInstanceCore`

## Usage

### Basic Example

```hcl
module "eks_node_groups" {
  source = "./modules/eks-node-groups"

  cluster = {
    name                       = "my-cluster"
    endpoint                   = module.eks_cluster.cluster_endpoint
    certificate_authority_data = module.eks_cluster.cluster_certificate_authority_data
    version                    = "1.29"
  }

  network = {
    vpc_id                 = "vpc-12345678"
    subnet_ids             = ["subnet-12345", "subnet-67890"]
    security_groups_ids    = ["sg-12345678"]
  }

  node_groups = {
    general = {
      desired_capacity = 2
      max_capacity     = 4
      min_capacity     = 1
      instance_types   = ["t3.medium"]
      capacity_type    = "ON_DEMAND"
      disk_size        = 50
      disk_type        = "gp3"
    }
  }

  settings = {
    enable_monitoring = true
    enable_imdsv2     = true
  }

  general_tags = {
    Environment = "production"
    Project     = "myapp"
    Owner       = "platform-team"
    Team        = "devops"
  }
}
```

### Advanced Example with Multiple Node Groups

```hcl
module "eks_node_groups" {
  source = "./modules/eks-node-groups"

  cluster = {
    name                       = "production-cluster"
    endpoint                   = module.eks_cluster.cluster_endpoint
    certificate_authority_data = module.eks_cluster.cluster_certificate_authority_data
    version                    = "1.29"
  }

  network = {
    vpc_id                 = data.aws_vpc.main.id
    subnet_ids             = data.aws_subnets.private.ids
    security_groups_ids    = [aws_security_group.worker_nodes.id]
  }

  node_groups = {
    # General purpose nodes
    general = {
      desired_capacity = 3
      max_capacity     = 10
      min_capacity     = 2
      instance_types   = ["t3.large", "t3.xlarge"]
      capacity_type    = "ON_DEMAND"
      disk_size        = 100
      disk_type        = "gp3"
      disk_throughput  = 250
      
      k8s_labels = {
        "node-type" = "general"
        "workload"  = "standard"
      }
      
      remote_access_enabled  = true
      ec2_ssh_key           = "my-key-pair"
      source_security_groups = [aws_security_group.bastion.id]
    }

    # Spot instances for non-critical workloads
    spot = {
      desired_capacity = 2
      max_capacity     = 8
      min_capacity     = 0
      instance_types   = ["t3.large", "t3.xlarge", "t3a.large"]
      capacity_type    = "SPOT"
      disk_size        = 50
      disk_type        = "gp3"
      
      k8s_labels = {
        "node-type" = "spot"
        "workload"  = "batch"
      }
      
      k8s_taints = [
        {
          key    = "spot-instance"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
      
      max_unavailable_percentage = 50
    }

    # High-performance nodes with NVME storage
    compute = {
      desired_capacity = 1
      max_capacity     = 5
      min_capacity     = 0
      instance_types   = ["c5n.2xlarge"]
      capacity_type    = "ON_DEMAND"
      disk_size        = 200
      disk_type        = "io2"
      disk_iops        = 1000
      
      k8s_labels = {
        "node-type" = "compute"
        "workload"  = "high-performance"
      }
      
      k8s_taints = [
        {
          key    = "compute-optimized"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }

    # ARM-based nodes
    arm = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 0
      instance_types   = ["t4g.large"]
      capacity_type    = "ON_DEMAND"
      disk_size        = 50
      disk_type        = "gp3"
      ami_type         = "AL2_ARM_64"
      
      k8s_labels = {
        "node-type"    = "arm"
        "architecture" = "arm64"
      }
    }
  }

  settings = {
    enable_monitoring = true
    enable_imdsv2     = true
    name_prefix       = "company"
    name_suffix       = "v1"
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
      "CostCenter" = "engineering"
      "Backup"     = "required"
    }
  }
}
```

### Spot-Only Configuration for Cost Optimization

```hcl
module "eks_spot_nodes" {
  source = "./modules/eks-node-groups"

  cluster = {
    name                       = var.cluster_name
    endpoint                   = var.cluster_endpoint
    certificate_authority_data = var.cluster_ca_data
    version                    = "1.29"
  }

  network = {
    vpc_id      = var.vpc_id
    subnet_ids  = var.private_subnet_ids
  }

  node_groups = {
    spot_workers = {
      desired_capacity = 5
      max_capacity     = 20
      min_capacity     = 2
      instance_types   = ["t3.medium", "t3.large", "t3a.medium", "t3a.large"]
      capacity_type    = "SPOT"
      disk_size        = 50
      disk_type        = "gp3"
      
      k8s_labels = {
        "node-lifecycle" = "spot"
        "cost-optimized" = "true"
      }
      
      max_unavailable_percentage = 75
    }
  }

  settings = {
    enable_monitoring = true
    enable_imdsv2     = true
  }

  general_tags = var.common_tags
}
```

## Inputs

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| cluster | EKS cluster configuration | `object` |
| network | Network settings for the node group | `object` |
| node_groups | Map of node group configurations | `map(object)` |
| settings | General configuration and tags | `object` |
| general_tags | General tags including Environment and Project | `object` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| optional_tags | Optional tags per resource type | `object` | `{}` |

### Cluster Object Structure

```hcl
cluster = {
  name                       = string           # EKS cluster name
  endpoint                   = string           # EKS cluster endpoint
  certificate_authority_data = string           # EKS cluster CA data
  version                    = optional(string, "1.32")  # Kubernetes version
}
```

### Network Object Structure

```hcl
network = {
  vpc_id                 = string                    # VPC ID
  subnet_ids             = list(string)              # List of subnet IDs
  security_groups_ids    = optional(list(string), []) # Additional security groups
}
```

### Node Groups Object Structure

```hcl
node_groups = {
  node_group_name = {
    # Capacity Configuration
    desired_capacity = number        # Desired number of nodes
    max_capacity     = number        # Maximum number of nodes
    min_capacity     = number        # Minimum number of nodes
    instance_types   = list(string)  # List of instance types
    capacity_type    = string        # "ON_DEMAND" or "SPOT"
    
    # Storage Configuration
    disk_size        = number                 # Root volume size in GB
    disk_type        = string                 # "gp3", "gp2", "io1", "io2"
    disk_iops        = optional(number)       # IOPS (for io1, io2, gp3)
    disk_throughput  = optional(number)       # Throughput (for gp3 only)
    
    # Kubernetes Configuration
    k8s_labels       = optional(map(string), {})  # Kubernetes labels
    k8s_taints       = optional(list(object({     # Kubernetes taints
      key    = string
      value  = string
      effect = string  # "NO_SCHEDULE", "NO_EXECUTE", "PREFER_NO_SCHEDULE"
    })), [])
    
    # AMI and Access Configuration
    ami_type                      = optional(string, "AL2_x86_64")  # AMI type
    remote_access_enabled         = optional(bool, false)          # Enable SSH access
    ec2_ssh_key                   = optional(string)               # SSH key name
    source_security_groups        = optional(list(string), [])     # SSH source SGs
    
    # Update Configuration
    max_unavailable               = optional(number, 1)       # Max unavailable nodes
    max_unavailable_percentage    = optional(number)          # Max unavailable percentage
    force_update_version          = optional(bool, false)     # Force version update
    
    # Advanced Configuration
    user_data                     = optional(string, "")           # Custom user data
    pre_bootstrap_user_data       = optional(string, "")          # Pre-bootstrap script
    post_bootstrap_user_data      = optional(string, "")          # Post-bootstrap script
    bootstrap_extra_args          = optional(string, "")          # Bootstrap arguments
    subnet_ids                    = optional(list(string))        # Override subnet IDs
    additional_security_group_ids = optional(list(string), [])    # Additional SGs
  }
}
```

### Settings Object Structure

```hcl
settings = {
  enable_monitoring = optional(bool, true)    # Enable detailed monitoring
  enable_imdsv2     = optional(bool, true)    # Enforce IMDSv2
  name_prefix       = optional(string, "")    # Name prefix
  name_suffix       = optional(string, "")    # Name suffix
}
```

## Outputs

| Name | Description |
|------|-------------|
| node_groups | Complete EKS node groups configuration |
| node_group_arns | ARNs of the EKS node groups |
| node_group_status | Status of the EKS node groups |
| node_role_arn | IAM role ARN for the EKS node groups |
| launch_template_ids | Launch template IDs for the node groups |
| launch_template_versions | Latest launch template versions |
| amis_used | AMI IDs and names used by each node group |

## AMI Types and Architecture

### Supported AMI Types

- `AL2_x86_64`: Amazon Linux 2 (x86_64)
- `AL2_x86_64_GPU`: Amazon Linux 2 with GPU support
- `AL2_ARM_64`: Amazon Linux 2 (ARM64/Graviton)
- `CUSTOM`: Custom AMI (requires additional configuration)

### Architecture Selection

The module automatically selects the appropriate architecture based on AMI type:

- `AL2_ARM_64` → ARM64
- All others → x86_64

## Storage Configuration

### Disk Types and Performance

| Type | Description | IOPS | Throughput | Use Case |
|------|-------------|------|------------|----------|
| `gp3` | General Purpose SSD (latest) | 3,000-16,000 | 125-1,000 MB/s | Most workloads |
| `gp2` | General Purpose SSD (legacy) | 100-16,000 | Up to 250 MB/s | Legacy systems |
| `io1` | Provisioned IOPS SSD | 100-64,000 | Up to 1,000 MB/s | High IOPS |
| `io2` | Provisioned IOPS SSD (latest) | 100-64,000 | Up to 1,000 MB/s | Mission critical |

### Disk Configuration Examples

```hcl
# High-performance storage
disk_size       = 200
disk_type       = "io2"
disk_iops       = 2000

# Cost-optimized storage
disk_size       = 50
disk_type       = "gp3"
disk_throughput = 150

# Standard storage
disk_size = 100
disk_type = "gp3"
```

## Kubernetes Taints and Effects

### Taint Effects

- `NO_SCHEDULE`: Pods cannot be scheduled on the node
- `NO_EXECUTE`: Pods are evicted from the node
- `PREFER_NO_SCHEDULE`: Kubernetes tries to avoid scheduling pods on the node

### Common Taint Examples

```hcl
# Spot instance taint
k8s_taints = [
  {
    key    = "spot-instance"
    value  = "true"
    effect = "NO_SCHEDULE"
  }
]

# GPU node taint
k8s_taints = [
  {
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }
]

# Dedicated workload taint
k8s_taints = [
  {
    key    = "dedicated"
    value  = "ml-workload"
    effect = "NO_EXECUTE"
  }
]
```

## Security Best Practices

### Instance Metadata Service (IMDS)

- **IMDSv2 Enforcement**: Set `enable_imdsv2 = true` to require token-based access
- **Hop Limit**: Limited to 2 hops for container access
- **Metadata Tags**: Enabled for enhanced monitoring

### Encryption

- **EBS Encryption**: All volumes encrypted by default
- **Delete on Termination**: Enabled for security

### SSH Access

```hcl
remote_access_enabled         = true
ec2_ssh_key                   = "my-key-pair"
source_security_groups        = ["sg-bastion"]  # Restrict SSH access
```

### Security Group Configuration

- Use dedicated security groups for worker nodes
- Implement least privilege access principles
- Separate security groups for different node group types

## Monitoring and Observability

### CloudWatch Monitoring

- **Detailed Monitoring**: Enabled by default (`enable_monitoring = true`)
- **Instance Tags**: Comprehensive tagging for cost allocation
- **Volume Monitoring**: EBS volume performance metrics

### Recommended Monitoring Setup

```hcl
settings = {
  enable_monitoring = true
  enable_imdsv2     = true
}

# Add monitoring-specific labels
k8s_labels = {
  "monitoring.coreos.com/enabled" = "true"
  "prometheus.io/scrape"          = "true"
}
```

## Cost Optimization Strategies

### Spot Instances

```hcl
capacity_type = "SPOT"
instance_types = ["t3.medium", "t3.large", "t3a.medium", "t3a.large"]
max_unavailable_percentage = 50
```

### Mixed Instance Types

```hcl
instance_types = ["t3.medium", "t3.large", "t3a.medium"]  # Diversify for availability
```

### Right-sizing Storage

```hcl
disk_type = "gp3"        # More cost-effective than gp2
disk_size = 50           # Start small, can be expanded
```

## Update Strategies

### Rolling Updates

```hcl
max_unavailable            = 1     # Number of nodes
max_unavailable_percentage = 25    # Percentage of nodes
force_update_version       = false # Gradual updates
```

### Blue-Green Deployments

```hcl
# Create new node group with different name
# Drain old node group
# Delete old node group
```

## Integration with Other Modules

## Troubleshooting

### Common Issues

1. **Node Group Creation Fails**
   - Check IAM permissions for node group role
   - Verify subnet availability zones match
   - Ensure AMI is available in the region

2. **Nodes Not Joining Cluster**
   - Verify security group rules allow cluster communication
   - Check user data script execution
   - Confirm IAM roles have required policies

3. **Spot Instance Interruptions**
   - Use diverse instance types
   - Implement graceful shutdown handling
   - Monitor spot instance interruption notices

4. **Storage Performance Issues**
   - Check IOPS limits for disk type
   - Verify throughput configuration for gp3
   - Monitor CloudWatch metrics

### Debugging Commands

```bash
# Check node group status
kubectl get nodes -o wide

# Check node group events
kubectl describe nodes

# Check AWS node group status
aws eks describe-nodegroup --cluster-name <cluster> --nodegroup-name <nodegroup>

# Check launch template
aws ec2 describe-launch-templates
```

## Prerequisites

1. **Existing EKS Cluster**: Node groups require an existing EKS cluster
2. **VPC and Subnets**: Properly configured networking
3. **Security Groups**: Appropriate security groups for worker nodes
4. **IAM Permissions**: Permissions to create IAM roles and policies
5. **SSH Key Pair**: (Optional) For remote access

## Version Compatibility

| Module Version | Terraform | AWS Provider | Kubernetes |
|---------------|-----------|--------------|------------|
| 1.x.x         | >= 1.0    | >= 4.0       | 1.21+      |

## Best Practices

1. **Use Multiple AZs**: Distribute nodes across availability zones
2. **Instance Diversity**: Use multiple instance types for resilience
3. **Taints and Labels**: Properly label and taint nodes for workload isolation
4. **Update Strategy**: Plan update strategies to minimize downtime
5. **Monitoring**: Enable comprehensive monitoring and logging
6. **Security**: Follow security best practices for access and encryption
7. **Cost Management**: Use spot instances and right-sized storage
8. **Backup**: Implement backup strategies for persistent workloads

## Contributing

When contributing to this module:

1. Test with multiple node group configurations
2. Verify security best practices
3. Update documentation for new features
4. Ensure backward compatibility
5. Test spot and on-demand instances

## License

This module is provided under the MIT License. See LICENSE file for details.
