# AWS EKS Platform Terraform Module

This comprehensive Terraform module creates a complete AWS EKS (Elastic Kubernetes Service) platform with all necessary infrastructure components. It provides a production-ready Kubernetes environment with VPC networking, security groups, EKS cluster, node groups, ECR repositories, S3 storage, SSL certificates, and essential Kubernetes add-ons.

## Features

- **Complete EKS Platform**: End-to-end Kubernetes infrastructure deployment
- **Multi-AZ VPC**: High-availability networking with public and private subnets
- **Security Groups**: Comprehensive network security for EKS components
- **EKS Cluster**: Managed Kubernetes control plane with encryption and logging
- **Node Groups**: Scalable worker nodes with auto-scaling capabilities
- **ECR Integration**: Container registry with lifecycle policies
- **S3 Storage**: Secure object storage with versioning and encryption
- **SSL Certificates**: ACM certificates for secure HTTPS communication
- **Parameter Store**: Centralized configuration management
- **IRSA Support**: IAM Roles for Service Accounts integration
- **Essential Add-ons**: Metrics server, cluster autoscaler, load balancer controller
- **EBS CSI Driver**: Persistent volume support with proper IAM roles

## Architecture Overview

```diagram
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS EKS Platform                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   Public AZ-a   │  │   Public AZ-b   │  │   Public AZ-c   │             │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │             │
│  │ │   ALB/NLB   │ │  │ │   ALB/NLB   │ │  │ │   ALB/NLB   │ │             │
│  │ │ NAT Gateway │ │  │ │ NAT Gateway │ │  │ │ NAT Gateway │ │             │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
│           │                     │                     │                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │  Private AZ-a   │  │  Private AZ-b   │  │  Private AZ-c   │             │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │             │
│  │ │ EKS Nodes   │ │  │ │ EKS Nodes   │ │  │ │ EKS Nodes   │ │             │
│  │ │ Jump Server │ │  │ │             │ │  │ │             │ │             │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         EKS Control Plane                          │   │
│  │  ┌───────────────┐ ┌───────────────┐ ┌───────────────────────────┐  │   │
│  │  │   API Server  │ │   etcd        │ │  Controller Manager       │  │   │
│  │  │   Scheduler   │ │   Cluster     │ │  Add-ons (CSI, CNI)       │  │   │
│  │  └───────────────┘ └───────────────┘ └───────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐   │
│  │     ECR     │ │     S3      │ │ Parameter   │ │   SSL Certificates  │   │
│  │ Repositories│ │   Buckets   │ │   Store     │ │     (ACM)           │   │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Production Setup

```hcl
module "eks_platform" {
  source = "./eks-platform"

  # General Configuration
  aws_region = "us-west-2"
  
  general_tags = {
    Environment = "production"
    Project     = "microservices"
    Owner       = "platform-team"
    Team        = "infrastructure"
    ManagedBy   = "terraform"
  }

  # Network Configuration
  network = {
    cidr_block     = "10.0.0.0/16"
    Azs            = ["us-west-2a", "us-west-2b", "us-west-2c"]
    public_subnet  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnet = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
    create_default_sg = true
  }

  # Security Groups
  security_group_config = {
    create_security_groups = true
    create_ingress_rules   = false
    create_egress_rules    = false
    security_groups = [
      {
        name        = "jump-server"
        description = "Jump server security group"
      },
      {
        name        = "eks-cluster"
        description = "EKS cluster security group"
      },
      {
        name        = "eks-node-group"
        description = "EKS node group security group"
      },
      {
        name        = "nlb"
        description = "Network Load Balancer security group"
      }
    ]
  }

  security_group_config_rules = {
    create_security_groups = false
    create_ingress_rules   = true
    create_egress_rules    = true
  }

  # EKS Cluster Configuration
  cluster = {
    name                      = "main"
    version                   = "1.28"
    enable_encryption         = true
    enable_cluster_log_types = ["api", "audit", "authenticator"]
    log_retention_in_days     = 7
    kms_key_deletion_window   = 10
  }

  cluster_network = {
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  # Node Groups
  eks_node_groups_config = {
    node_groups = {
      general = {
        desired_capacity   = 2
        max_capacity      = 4
        min_capacity      = 1
        instance_types    = ["t3.medium"]
        capacity_type     = "ON_DEMAND"
        disk_size         = 50
        disk_type         = "gp3"
        k8s_labels = {
          role = "general"
          environment = "production"
        }
        k8s_taints = []
      }
    }
    settings = {
      enable_monitoring = true
      enable_imdsv2     = true
      name_prefix       = ""
      name_suffix       = ""
    }
  }

  # EKS Add-ons
  eks_addons = [
    {
      name = "vpc-cni"
    },
    {
      name = "coredns"
    },
    {
      name = "kube-proxy"
    },
    {
      name = "aws-ebs-csi-driver"
    }
  ]

  # ECR Repositories
  ecr_repositories = [
    {
      name                 = "web-app"
      scan_on_push         = true
      image_tag_mutability = "MUTABLE"
      lifecycle_policy_rules = [
        {
          rulePriority  = 1
          description   = "Keep last 10 production images"
          tagStatus     = "tagged"
          tagPrefixList = ["prod"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
          action_type   = "expire"
        },
        {
          rulePriority  = 2
          description   = "Keep last 5 staging images"
          tagStatus     = "tagged"
          tagPrefixList = ["staging"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
          action_type   = "expire"
        }
      ]
    }
  ]

  # S3 Buckets
  s3_buckets = {
    application-data = {
      versioning = true
      encryption = true
    }
    backups = {
      versioning = true
      encryption = true
    }
    logs = {
      versioning = false
      encryption = true
    }
  }

  # SSL Certificates
  ssl_certificate = {
    domain_name = "api.example.com"
    subject_alternative_names = [
      "www.api.example.com",
      "admin.api.example.com"
    ]
  }

  auto_validate_certificates = false

  # Parameter Store
  parameters = {
    "app/database/host" = {
      type        = "String"
      value       = "db.example.com"
      description = "Database hostname"
    }
    "app/database/password" = {
      type        = "SecureString"
      value       = "super-secure-password"
      description = "Database password"
    }
    "app/api/jwt-secret" = {
      type        = "SecureString"
      value       = "jwt-signing-secret"
      description = "JWT signing secret"
    }
  }

  # IRSA Configuration
  irsa_config = {
    github_repo = "your-org/your-repo"
  }

  # Kubernetes Resources
  k8s_resources_config = {
    install_metrics_server           = true
    install_cluster_autoscaler       = true
    install_load_balancer_controller = true
    enable_irsa                      = true

    metrics_server_config = {
      kubelet_insecure_tls            = false
      kubelet_preferred_address_types = ["InternalIP"]
    }

    namespaces = [
      {
        name = "production"
        labels = {
          environment = "production"
          managed-by  = "terraform"
        }
        annotations = {
          "scheduler.alpha.kubernetes.io/node-selector" = "environment=production"
        }
      },
      {
        name = "monitoring"
        labels = {
          purpose = "monitoring"
        }
      }
    ]
  }

  # Network Security
  office_cidr_blocks = ["203.0.113.0/24"]  # Replace with your office IP range
  vpc_cidr_block     = "10.0.0.0/16"
}
```

### Development Environment Setup

```hcl
module "eks_dev" {
  source = "./eks-platform"

  aws_region = "us-west-2"
  
  general_tags = {
    Environment = "development"
    Project     = "microservices"
    Owner       = "dev-team"
    Team        = "development"
    ManagedBy   = "terraform"
  }

  # Smaller network for development
  network = {
    cidr_block     = "10.1.0.0/16"
    Azs            = ["us-west-2a", "us-west-2b"]
    public_subnet  = ["10.1.1.0/24", "10.1.2.0/24"]
    private_subnet = ["10.1.11.0/24", "10.1.12.0/24"]
    create_default_sg = true
  }

  # Basic security groups
  security_group_config = {
    create_security_groups = true
    security_groups = [
      {
        name        = "jump-server"
        description = "Development jump server"
      },
      {
        name        = "eks-cluster"
        description = "Development EKS cluster"
      },
      {
        name        = "eks-node-group"
        description = "Development EKS nodes"
      },
      {
        name        = "nlb"
        description = "Development load balancer"
      }
    ]
  }

  security_group_config_rules = {
    create_security_groups = false
    create_ingress_rules   = true
    create_egress_rules    = true
  }

  # Smaller cluster for dev
  cluster = {
    name                      = "dev"
    version                   = "1.28"
    enable_encryption         = false  # Cost optimization
    enable_cluster_log_types = ["api"]
    log_retention_in_days     = 3
    kms_key_deletion_window   = 7
  }

  cluster_network = {
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  # Single node group for development
  eks_node_groups_config = {
    node_groups = {
      dev = {
        desired_capacity   = 1
        max_capacity      = 2
        min_capacity      = 1
        instance_types    = ["t3.small"]
        capacity_type     = "SPOT"  # Cost optimization
        disk_size         = 30
        disk_type         = "gp3"
        k8s_labels = {
          role = "development"
          environment = "dev"
        }
      }
    }
    settings = {
      enable_monitoring = false  # Cost optimization
      enable_imdsv2     = true
      name_prefix       = "dev"
      name_suffix       = ""
    }
  }

  # Essential add-ons only
  eks_addons = [
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

  # Development ECR repositories
  ecr_repositories = [
    {
      name                 = "dev-app"
      scan_on_push         = false
      image_tag_mutability = "MUTABLE"
      lifecycle_policy_rules = [
        {
          rulePriority  = 1
          description   = "Keep last 5 images"
          tagStatus     = "untagged"
          tagPrefixList = []
          countType     = "imageCountMoreThan"
          countNumber   = 5
          action_type   = "expire"
        }
      ]
    }
  ]

  # Development storage
  s3_buckets = {
    dev-data = {
      versioning = false
      encryption = false
    }
  }

  # Development certificate
  ssl_certificate = {
    domain_name = "dev-api.example.com"
    subject_alternative_names = []
  }

  # Basic parameters
  parameters = {
    "dev/app/debug" = {
      type        = "String"
      value       = "true"
      description = "Enable debug mode"
    }
  }

  irsa_config = {
    github_repo = "your-org/your-repo"
  }

  k8s_resources_config = {
    install_metrics_server           = true
    install_cluster_autoscaler       = false  # Not needed for small dev cluster
    install_load_balancer_controller = true
    enable_irsa                      = true

    metrics_server_config = {
      kubelet_insecure_tls            = true  # Development setting
      kubelet_preferred_address_types = ["InternalIP"]
    }

    namespaces = [
      {
        name = "development"
        labels = {
          environment = "development"
        }
      }
    ]
  }

  office_cidr_blocks = ["0.0.0.0/0"]  # Less restrictive for development
}
```

### Multi-Environment with Shared Services

```hcl
# Shared ECR and Parameter Store
module "shared_services" {
  source = "./eks-platform"

  aws_region = "us-west-2"
  
  general_tags = {
    Environment = "shared"
    Project     = "platform"
    Owner       = "platform-team"
    Team        = "infrastructure"
    ManagedBy   = "terraform"
  }

  # Minimal network for shared services
  network = {
    cidr_block     = "10.255.0.0/16"
    Azs            = ["us-west-2a"]
    public_subnet  = ["10.255.1.0/24"]
    private_subnet = ["10.255.11.0/24"]
    create_default_sg = true
  }

  # Skip EKS cluster creation (ECR and Parameter Store only)
  cluster = {
    name                      = "shared"
    version                   = "1.28"
    enable_encryption         = true
    enable_cluster_log_types = []
    log_retention_in_days     = 7
    kms_key_deletion_window   = 10
  }

  # Shared ECR repositories
  ecr_repositories = [
    {
      name                 = "shared/base-images"
      scan_on_push         = true
      image_tag_mutability = "IMMUTABLE"
      lifecycle_policy_rules = [
        {
          rulePriority  = 1
          description   = "Keep last 20 production images"
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 20
          action_type   = "expire"
        }
      ]
    },
    {
      name                 = "shared/monitoring"
      scan_on_push         = true
      image_tag_mutability = "MUTABLE"
      lifecycle_policy_rules = []
    }
  ]

  # Shared configuration
  parameters = {
    "shared/monitoring/grafana-admin-password" = {
      type        = "SecureString"
      value       = "secure-grafana-password"
      description = "Grafana admin password"
    }
    "shared/registry/endpoint" = {
      type        = "String"
      value       = "123456789012.dkr.ecr.us-west-2.amazonaws.com"
      description = "ECR registry endpoint"
    }
  }
}

# Production Environment
module "production_eks" {
  source = "./eks-platform"

  # Production-specific configuration
  # Uses shared ECR repositories and parameters
  
  depends_on = [module.shared_services]
}

# Staging Environment
module "staging_eks" {
  source = "./eks-platform"

  # Staging-specific configuration
  # Uses shared ECR repositories and parameters
  
  depends_on = [module.shared_services]
}
```

## Input Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| general_tags | Required base tags for all resources | `object` |
| network | Network configuration for VPC and subnets | `object` |
| security_group_config | Security groups configuration | `object` |
| security_group_config_rules | Security group rules configuration | `object` |
| cluster | EKS cluster configuration | `object` |
| cluster_network | EKS cluster network configuration | `object` |
| eks_node_groups_config | Node groups configuration | `object` |
| eks_addons | EKS add-ons to install | `list(object)` |
| ecr_repositories | ECR repositories configuration | `list(object)` |
| s3_buckets | S3 buckets configuration | `map(object)` |
| ssl_certificate | SSL certificate configuration | `object` |
| parameters | Parameter Store configuration | `map(object)` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| aws_region | AWS region | `string` | `"us-west-2"` |
| name_prefix | Name prefix for resources | `string` | `""` |
| name_suffix | Name suffix for resources | `string` | `""` |
| auto_validate_certificates | Auto-validate SSL certificates | `bool` | `false` |
| irsa_config | IRSA configuration | `object` | `{github_repo = ""}` |
| k8s_resources_config | Kubernetes resources configuration | `object` | Default config |
| office_cidr_blocks | Office IP ranges for SSH access | `list(string)` | `["0.0.0.0/0"]` |

### Detailed Configuration Objects

#### General Tags

```hcl
general_tags = {
  Environment = string                          # Environment name
  Owner       = string                          # Resource owner
  Project     = string                          # Project name
  Team        = string                          # Responsible team
  ManagedBy   = optional(string, "terraform")   # Management tool
}
```

#### Network Configuration

```hcl
network = {
  cidr_block        = string        # VPC CIDR block
  Azs               = list(string)  # Availability zones
  private_subnet    = list(string)  # Private subnet CIDRs
  public_subnet     = list(string)  # Public subnet CIDRs
  create_default_sg = bool          # Create default security group
}
```

#### EKS Cluster Configuration

```hcl
cluster = {
  name                      = string        # Cluster name
  version                   = string        # Kubernetes version
  enable_encryption         = bool          # Enable encryption at rest
  enable_cluster_log_types = list(string)  # CloudWatch log types
  log_retention_in_days     = number        # Log retention period
  kms_key_deletion_window   = number        # KMS key deletion window
}
```

#### Node Groups Configuration

```hcl
eks_node_groups_config = {
  node_groups = map(object({
    desired_capacity   = number        # Desired number of nodes
    max_capacity      = number        # Maximum number of nodes
    min_capacity      = number        # Minimum number of nodes
    instance_types    = list(string)  # EC2 instance types
    capacity_type     = string        # ON_DEMAND or SPOT
    disk_size         = number        # EBS volume size
    disk_type         = string        # EBS volume type
    k8s_labels        = map(string)   # Kubernetes labels
    k8s_taints        = list(object)  # Kubernetes taints
  }))
  settings = object({
    enable_monitoring = bool    # CloudWatch monitoring
    enable_imdsv2     = bool    # IMDSv2 enforcement
    name_prefix       = string  # Node group name prefix
    name_suffix       = string  # Node group name suffix
  })
}
```

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | EKS cluster name |
| created_namespaces | List of created Kubernetes namespaces |
| vpc_id | VPC ID |
| main_api_certificate_arn | SSL certificate ARN |
| configure_kubectl | kubectl configuration command |
| next_steps | Post-deployment instructions |

### Output Examples

```bash
# Configure kubectl
aws eks --region us-west-2 update-kubeconfig --name production-microservices-main-cluster

# Certificate ARN
arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012

# Created namespaces
["production", "monitoring", "kube-system"]
```

## Component Details

### VPC Module

- **Multi-AZ deployment** with public and private subnets
- **Internet Gateway** for public subnet connectivity
- **NAT Gateways** for private subnet outbound access
- **Route tables** for proper traffic routing
- **DNS resolution** enabled for internal communication

### Security Groups Module

- **Jump Server** security group for administrative access
- **EKS Cluster** security group for control plane
- **EKS Node Group** security group for worker nodes
- **Load Balancer** security group for ingress traffic
- **Configurable rules** for custom security requirements

### EKS Cluster Module

- **Managed Kubernetes** control plane
- **Encryption at rest** for secrets and configuration
- **CloudWatch logging** for audit and troubleshooting
- **OIDC provider** for IRSA integration
- **Multiple add-ons** support

### Node Groups Module

- **Auto Scaling Groups** for dynamic scaling
- **Multi-AZ distribution** for high availability
- **Spot and On-Demand** instance support
- **Custom AMIs** and user data scripts
- **Kubernetes labels and taints**

### ECR Module

- **Container image repositories** with scanning
- **Lifecycle policies** for image cleanup
- **Image tag mutability** controls
- **Cross-region replication** support

### S3 Module

- **Object storage** with versioning
- **Server-side encryption** for data protection
- **Bucket policies** for access control
- **Lifecycle management** for cost optimization

### SSL Certificates Module

- **ACM certificates** with DNS validation
- **Multi-domain support** with SANs
- **Automatic renewal** for active certificates
- **Regional deployment** for CloudFront and ALB

### Parameter Store Module

- **Centralized configuration** management
- **Secure string** support for sensitive data
- **Hierarchical organization** by environment/service
- **Integration** with application deployments

### Kubernetes Resources Module

- **Metrics Server** for resource monitoring
- **Cluster Autoscaler** for automatic scaling
- **Load Balancer Controller** for ingress
- **Custom namespaces** with labels and annotations

## Security Features

### Network Security

- **Private subnets** for worker nodes
- **Security groups** with least privilege rules
- **Network ACLs** for additional security layers
- **VPC Flow Logs** for network monitoring

### EKS Security

- **IAM roles** for service accounts (IRSA)
- **Pod security standards** enforcement
- **Network policies** for pod-to-pod communication
- **Encryption** for data at rest and in transit

### Container Security

- **ECR image scanning** for vulnerabilities
- **Image tag immutability** for production images
- **Lifecycle policies** for image management
- **Registry access** controls

### Access Control

- **Jump server** for secure administrative access
- **SSL certificates** for encrypted communication
- **Parameter Store** for secure configuration
- **IAM policies** with least privilege

## Monitoring and Observability

### CloudWatch Integration

```hcl
# EKS cluster logs
enable_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

# Node group monitoring
enable_monitoring = true

# VPC Flow Logs
resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
}
```

### Kubernetes Monitoring

```yaml
# Metrics Server for resource metrics
apiVersion: v1
kind: ConfigMap
metadata:
  name: metrics-server-config
data:
  kubelet-insecure-tls: "false"
  kubelet-preferred-address-types: "InternalIP"
```

### Application Monitoring

```hcl
# CloudWatch Container Insights
resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name = module.eks_cluster.cluster_name
  addon_name   = "amazon-cloudwatch-observability"
}
```

## Deployment Process

### Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **kubectl** installed for cluster management
4. **Domain access** for SSL certificate validation

### Step-by-Step Deployment

1. **Initialize Terraform**

   ```bash
   terraform init
   ```

2. **Plan Deployment**

   ```bash
   terraform plan -var-file="production.tfvars"
   ```

3. **Apply Configuration**

   ```bash
   terraform apply -var-file="production.tfvars"
   ```

4. **Configure kubectl**

   ```bash
   aws eks --region us-west-2 update-kubeconfig --name production-microservices-main-cluster
   ```

5. **Verify Deployment**

   ```bash
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

6. **Add DNS Records**

   ```bash
   # Add DNS validation records from terraform output
   terraform output next_steps
   ```

### Post-Deployment Configuration

#### Install Additional Tools

```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add Helm repositories
helm repo add stable https://charts.helm.sh/stable
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```

#### Deploy Applications

```yaml
# Example application deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web-app
        image: 123456789012.dkr.ecr.us-west-2.amazonaws.com/microservices/web-app:latest
        ports:
        - containerPort: 8080
```

## Cost Optimization

### Node Group Optimization

```hcl
# Use Spot instances for cost savings
capacity_type = "SPOT"

# Right-size instance types
instance_types = ["t3.medium", "t3a.medium", "t3.large"]

# Enable cluster autoscaler
install_cluster_autoscaler = true
```

### Storage Optimization

```hcl
# Use gp3 volumes for better price/performance
disk_type = "gp3"

# Lifecycle policies for ECR
lifecycle_policy_rules = [
  {
    rulePriority  = 1
    description   = "Keep last 10 images"
    countType     = "imageCountMoreThan"
    countNumber   = 10
    action_type   = "expire"
  }
]
```

### Network Cost Optimization

```hcl
# Single NAT Gateway for dev environments
# Multiple NAT Gateways for production (HA)

# Use VPC endpoints for AWS services
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
}
```

## Troubleshooting

### Common Issues

1. **Node Group Creation Failed**

   ```bash
   # Check IAM permissions
   aws iam get-role --role-name eks-node-group-role
   
   # Verify subnet tags
   aws ec2 describe-subnets --subnet-ids subnet-12345 --query 'Subnets[0].Tags'
   ```

2. **Pods Stuck in Pending**

   ```bash
   # Check node capacity
   kubectl describe nodes
   
   # Check pod resource requests
   kubectl describe pod <pod-name> -n <namespace>
   
   # Check cluster autoscaler logs
   kubectl logs -n kube-system deployment/cluster-autoscaler
   ```

3. **Load Balancer Controller Issues**

   ```bash
   # Check controller logs
   kubectl logs -n kube-system deployment/aws-load-balancer-controller
   
   # Verify IRSA configuration
   kubectl describe serviceaccount aws-load-balancer-controller -n kube-system
   ```

4. **Certificate Validation Timeout**

   ```bash
   # Check DNS records
   nslookup _acme-challenge.api.example.com
   
   # Verify certificate status
   aws acm describe-certificate --certificate-arn <certificate-arn>
   ```

5. **ECR Push Permission Denied**

   ```bash
   # Get ECR login token
   aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-west-2.amazonaws.com
   
   # Check repository permissions
   aws ecr describe-repositories --repository-names microservices/web-app
   ```

### Debugging Commands

```bash
# Cluster status
kubectl cluster-info
kubectl get componentstatuses

# Node diagnostics
kubectl get nodes -o wide
kubectl describe node <node-name>

# Pod diagnostics
kubectl get pods --all-namespaces -o wide
kubectl logs <pod-name> -n <namespace> --previous

# Network diagnostics
kubectl get svc --all-namespaces
kubectl get ingress --all-namespaces

# Storage diagnostics
kubectl get pv
kubectl get pvc --all-namespaces

# Check add-on status
kubectl get deployment -n kube-system
kubectl get daemonset -n kube-system

# EKS add-ons status
aws eks describe-addon --cluster-name <cluster-name> --addon-name vpc-cni
```

### Resource Validation

```bash
# Terraform state verification
terraform state list
terraform state show module.eks_cluster.aws_eks_cluster.main

# AWS resource verification
aws eks describe-cluster --name production-microservices-main-cluster
aws ec2 describe-vpcs --vpc-ids vpc-12345678
aws ecr describe-repositories

# Kubernetes resource verification
kubectl api-resources
kubectl get all --all-namespaces
```

## Performance Optimization

### Cluster Performance

1. **Node Group Configuration**

   ```hcl
   # Use latest generation instances
   instance_types = ["m6i.large", "m6i.xlarge", "m6a.large"]
   
   # Enable enhanced networking
   enable_monitoring = true
   
   # Optimize disk performance
   disk_type = "gp3"
   disk_size = 100
   ```

2. **Pod Resource Management**

   ```yaml
   # Set appropriate resource requests and limits
   resources:
     requests:
       memory: "256Mi"
       cpu: "250m"
     limits:
       memory: "512Mi"
       cpu: "500m"
   ```

### Network Performance

1. **VPC CNI Optimization**

   ```hcl
   # Configure VPC CNI for better performance
   eks_addons = [
     {
       name = "vpc-cni"
       configuration_values = jsonencode({
         env = {
           ENABLE_PREFIX_DELEGATION = "true"
           WARM_PREFIX_TARGET = "1"
         }
       })
     }
   ]
   ```

2. **Load Balancer Optimization**

   ```yaml
   # Use Network Load Balancer for better performance
   apiVersion: v1
   kind: Service
   metadata:
     annotations:
       service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
       service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
   ```

### Storage Performance

1. **EBS CSI Driver Configuration**

   ```yaml
   # Use gp3 volumes with custom IOPS
   apiVersion: v1
   kind: StorageClass
   metadata:
     name: gp3-fast
   provisioner: ebs.csi.aws.com
   parameters:
     type: gp3
     iops: "3000"
     throughput: "125"
   ```

## Security Hardening

### Cluster Security

1. **Enable Pod Security Standards**

   ```yaml
   # Pod Security Standards
   apiVersion: v1
   kind: Namespace
   metadata:
     name: production
     labels:
       pod-security.kubernetes.io/enforce: restricted
       pod-security.kubernetes.io/audit: restricted
       pod-security.kubernetes.io/warn: restricted
   ```

2. **Network Policies**

   ```yaml
   # Default deny all network policy
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: default-deny-all
     namespace: production
   spec:
     podSelector: {}
     policyTypes:
     - Ingress
     - Egress
   ```

### Node Security

1. **Security Groups**

   ```hcl
   # Restrict SSH access to jump server only
   ingress_rules = [
     {
       from_port                = 22
       to_port                  = 22
       protocol                 = "tcp"
       source_security_group_id = module.security_groups.security_group_ids["jump-server"]
       description              = "SSH from jump server only"
     }
   ]
   ```

2. **IMDSv2 Enforcement**

   ```hcl
   # Enforce IMDSv2
   settings = {
     enable_imdsv2 = true
   }
   ```

### Container Security

1. **ECR Image Scanning**

   ```hcl
   # Enable vulnerability scanning
   ecr_repositories = [
     {
       scan_on_push = true
       image_tag_mutability = "IMMUTABLE"  # For production
     }
   ]
   ```

2. **Runtime Security**

   ```yaml
   # Non-root containers
   securityContext:
     runAsNonRoot: true
     runAsUser: 1000
     readOnlyRootFilesystem: true
     allowPrivilegeEscalation: false
   ```

## Backup and Disaster Recovery

### Cluster Backup

1. **etcd Backups**

   ```bash
   # EKS automatically backs up etcd
   # Verify backup retention
   aws eks describe-cluster --name <cluster-name> --query 'cluster.logging'
   ```

2. **Application Data Backup**

   ```yaml
   # Velero for cluster backups
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: velero-config
   data:
     velero-backup-schedule: "0 2 * * *"  # Daily at 2 AM
   ```

### Cross-Region DR

1. **Multi-Region Setup**

   ```hcl
   # Primary region
   provider "aws" {
     alias  = "primary"
     region = "us-west-2"
   }
   
   # DR region
   provider "aws" {
     alias  = "dr"
     region = "us-east-1"
   }
   
   module "eks_dr" {
     source = "./eks-platform"
     providers = {
       aws = aws.dr
     }
     # DR-specific configuration
   }
   ```

2. **Data Replication**

   ```hcl
   # S3 cross-region replication
   resource "aws_s3_bucket_replication_configuration" "replication" {
     bucket = module.s3.buckets.application-data.id
     
     rule {
       id     = "replicate-to-dr"
       status = "Enabled"
       
       destination {
         bucket        = "arn:aws:s3:::dr-application-data"
         storage_class = "STANDARD_IA"
       }
     }
   }
   ```

## Compliance and Governance

### Tagging Strategy

```hcl
# Comprehensive tagging for compliance
general_tags = {
  Environment         = "production"
  Project            = "microservices"
  Owner              = "platform-team"
  Team               = "infrastructure"
  ManagedBy          = "terraform"
  CostCenter         = "engineering"
  Compliance         = "sox-pci"
  DataClassification = "confidential"
  BackupRequired     = "true"
  DRRequired         = "true"
}
```

### Resource Naming Standards

```docs
# Naming Convention: {prefix}-{environment}-{project}-{resource-type}-{suffix}
Examples:
- prod-production-microservices-main-cluster-v2
- staging-staging-api-web-nodegroup
- dev-development-frontend-ecr-repo
```

### Cost Management

1. **Resource Tagging for Cost Allocation**

   ```hcl
   # Cost allocation tags
   optional_tags = {
     vpc = {
       "aws:cost-allocation:project" = var.general_tags.Project
       "aws:cost-allocation:team"    = var.general_tags.Team
     }
   }
   ```

2. **Budget Alerts**

   ```hcl
   resource "aws_budgets_budget" "eks_budget" {
     name         = "${var.general_tags.Project}-eks-budget"
     budget_type  = "COST"
     limit_amount = "500"
     limit_unit   = "USD"
     time_unit    = "MONTHLY"
   
     cost_filters {
       service = ["Amazon Elastic Container Service for Kubernetes"]
       tag {
         key    = "Project"
         values = [var.general_tags.Project]
       }
     }
   }
   ```

## Migration Strategies

### From Existing Infrastructure

1. **Blue-Green Deployment**

   ```hcl
   # Create new EKS cluster alongside existing
   module "eks_blue" {
     source = "./eks-platform"
     name_suffix = "blue"
     # Current configuration
   }
   
   module "eks_green" {
     source = "./eks-platform"
     name_suffix = "green"
     # New configuration
   }
   ```

2. **Gradual Migration**

   ```bash
   # Migrate services incrementally
   kubectl apply -f service-a-deployment.yaml
   # Test and validate
   kubectl apply -f service-b-deployment.yaml
   # Continue until complete
   ```

### From Other Kubernetes Distributions

1. **Application Migration**

   ```bash
   # Export existing manifests
   kubectl get all --all-namespaces -o yaml > existing-resources.yaml
   
   # Modify for EKS compatibility
   # Apply to new cluster
   kubectl apply -f modified-resources.yaml
   ```

2. **Data Migration**

   ```bash
   # Use velero for backup/restore
   velero backup create migration-backup --include-namespaces production
   velero restore create --from-backup migration-backup
   ```

## Prerequisites

1. **AWS Account**: Valid AWS account with EKS permissions
2. **IAM Permissions**: Comprehensive permissions for EKS, VPC, IAM, and other services
3. **Domain Access**: Control over DNS for SSL certificate validation
4. **Tool Requirements**:
   - Terraform >= 1.0
   - AWS CLI >= 2.0
   - kubectl >= 1.25
   - Docker (for ECR operations)

## Version Compatibility

| Component | Version | Compatibility |
|-----------|---------|---------------|
| Terraform | >= 1.0 | All features |
| AWS Provider | ~> 5.0 | Latest features |
| Kubernetes Provider | ~> 2.20 | EKS integration |
| Helm Provider | ~> 2.10 | Chart deployments |
| EKS | 1.28+ | Recommended |
| Node AMI | Latest | Auto-updated |

## Best Practices Summary

### Infrastructure

1. **Multi-AZ Deployment**: Always deploy across multiple availability zones
2. **Network Segmentation**: Use private subnets for worker nodes
3. **Security Groups**: Implement least privilege access rules
4. **Encryption**: Enable encryption at rest and in transit

### Operations

1. **Monitoring**: Implement comprehensive logging and monitoring
2. **Backup**: Regular backups of critical data and configurations
3. **Updates**: Keep cluster and node groups updated
4. **Cost Management**: Regular cost reviews and optimization

### Security

1. **IRSA**: Use IAM roles for service accounts
2. **Network Policies**: Implement pod-to-pod communication restrictions
3. **Image Scanning**: Scan container images for vulnerabilities
4. **Access Control**: Use RBAC and pod security standards

### Development

1. **GitOps**: Use GitOps workflows for deployments
2. **CI/CD**: Implement automated testing and deployment pipelines
3. **Environment Parity**: Maintain consistency across environments
4. **Documentation**: Keep architecture and runbooks updated

## Contributing

When contributing to this platform:

1. Test changes in development environment first
2. Update documentation for any new features
3. Follow security best practices
4. Maintain backward compatibility
5. Add appropriate tests and validation
6. Update version compatibility matrices

## License

This module is provided under the MIT License. See LICENSE file for details.
