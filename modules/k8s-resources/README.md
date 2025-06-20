# Kubernetes Resources Module

This Terraform module deploys essential Kubernetes resources and components for AWS EKS clusters. It provides a comprehensive setup for cluster operations including metrics collection, auto-scaling, load balancing, and namespace management with IRSA (IAM Roles for Service Accounts) integration.

## Features

- **Essential Components**: Deploy critical cluster components in one module
- **Metrics Server**: Kubernetes metrics collection for HPA and resource monitoring
- **Cluster Autoscaler**: Automatic node scaling based on pod requirements
- **AWS Load Balancer Controller**: Advanced ingress and load balancing capabilities
- **Namespace Management**: Automated namespace creation with labels and annotations
- **IRSA Integration**: Complete IAM Roles for Service Accounts setup
- **Flexible Configuration**: Configurable versions and settings for all components
- **Resource Optimization**: Pre-configured resource requests and limits
- **Security Best Practices**: Least privilege IAM policies and secure configurations

## Architecture

The module deploys the following components:

### Core Components

1. **Metrics Server**: Collects resource metrics from kubelets
2. **Cluster Autoscaler**: Scales node groups based on pod scheduling needs
3. **AWS Load Balancer Controller**: Manages ALB/NLB for Kubernetes services

### Supporting Resources

1. **IAM Roles**: Service-specific roles with minimal required permissions
2. **IAM Policies**: AWS managed and custom policies for each component
3. **Namespaces**: Application namespaces with custom labels and annotations
4. **OIDC Provider**: Optional OIDC provider for IRSA (if not already existing)

## Usage

### Basic Example

```hcl
module "k8s_resources" {
  source = "./modules/k8s-resources"

  cluster_name             = "my-cluster"
  cluster_endpoint         = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate   = module.eks_cluster.cluster_certificate_authority_data
  cluster_oidc_issuer_url  = module.eks_cluster.oidc_provider_url_https
  oidc_provider_arn        = module.eks_cluster.oidc_provider_arn
  aws_region               = "us-west-2"
  vpc_id                   = "vpc-12345678"

  # Install all components with defaults
  install_metrics_server           = true
  install_cluster_autoscaler       = true
  install_load_balancer_controller = true

  # Create application namespaces
  namespaces = [
    {
      name = "production"
      labels = {
        "environment" = "production"
        "team"        = "platform"
      }
    },
    {
      name = "staging"
      labels = {
        "environment" = "staging"
        "team"        = "platform"
      }
    }
  ]

  tags = {
    Environment = "production"
    Project     = "myapp"
    ManagedBy   = "terraform"
  }
}
```

### Advanced Configuration Example

```hcl
module "k8s_resources" {
  source = "./modules/k8s-resources"

  cluster_name             = "production-cluster"
  cluster_endpoint         = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate   = module.eks_cluster.cluster_certificate_authority_data
  cluster_oidc_issuer_url  = module.eks_cluster.oidc_provider_url_https
  oidc_provider_arn        = module.eks_cluster.oidc_provider_arn
  aws_region               = var.aws_region
  vpc_id                   = var.vpc_id

  # Component versions
  metrics_server_version                    = "3.11.0"
  cluster_autoscaler_version               = "9.29.0"
  load_balancer_controller_version         = "1.6.2"
  load_balancer_controller_policy_version  = "v2.7.2"

  # Cluster autoscaler fine-tuning
  cluster_autoscaler_config = {
    scale_down_delay_after_add           = "10m"
    scale_down_unneeded_time            = "10m"
    scale_down_utilization_threshold    = "0.5"
    skip_nodes_with_local_storage       = true
    skip_nodes_with_system_pods         = true
  }

  # Metrics server configuration
  metrics_server_config = {
    kubelet_insecure_tls                = false
    kubelet_preferred_address_types     = ["InternalIP"]
  }

  # Application namespaces with detailed configuration
  namespaces = [
    {
      name = "api-production"
      labels = {
        "environment"                   = "production"
        "team"                         = "backend"
        "app.kubernetes.io/component"  = "api"
        "istio-injection"              = "enabled"
      }
      annotations = {
        "scheduler.alpha.kubernetes.io/node-selector" = "workload-type=api"
      }
    },
    {
      name = "web-production"
      labels = {
        "environment"                   = "production"
        "team"                         = "frontend"
        "app.kubernetes.io/component"  = "web"
      }
    },
    {
      name = "monitoring"
      labels = {
        "environment" = "production"
        "team"        = "platform"
        "purpose"     = "monitoring"
      }
      annotations = {
        "iam.amazonaws.com/permitted" = "monitoring-service-account"
      }
    }
  ]

  # Use existing OIDC provider
  enable_irsa = false

  tags = {
    Environment = "production"
    Project     = "myapp"
    Owner       = "platform-team"
    Team        = "devops"
    ManagedBy   = "terraform"
  }
}
```

### Minimal Setup (Metrics Server Only)

```hcl
module "k8s_basic" {
  source = "./modules/k8s-resources"

  cluster_name             = var.cluster_name
  cluster_endpoint         = var.cluster_endpoint
  cluster_ca_certificate   = var.cluster_ca_certificate
  cluster_oidc_issuer_url  = var.cluster_oidc_issuer_url
  oidc_provider_arn        = var.oidc_provider_arn
  aws_region               = var.aws_region
  vpc_id                   = var.vpc_id

  # Install only metrics server
  install_metrics_server           = true
  install_cluster_autoscaler       = false
  install_load_balancer_controller = false

  namespaces = [
    {
      name = "default-app"
      labels = {
        "app" = "default"
      }
    }
  ]

  tags = var.common_tags
}
```

## Inputs

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| cluster_name | Name of the EKS cluster | `string` |
| cluster_endpoint | EKS cluster endpoint | `string` |
| cluster_ca_certificate | EKS cluster certificate authority data | `string` |
| cluster_oidc_issuer_url | EKS cluster OIDC issuer URL | `string` |
| aws_region | AWS region | `string` |
| vpc_id | VPC ID where cluster is deployed | `string` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| oidc_provider_arn | OIDC provider ARN | `string` | `null` |
| install_metrics_server | Whether to install metrics server | `bool` | `true` |
| install_cluster_autoscaler | Whether to install cluster autoscaler | `bool` | `true` |
| install_load_balancer_controller | Whether to install AWS Load Balancer Controller | `bool` | `true` |
| enable_irsa | Whether to create OIDC provider for IRSA | `bool` | `true` |
| namespaces | List of namespaces to create | `list(object)` | `[]` |
| tags | Tags to apply to resources | `map(string)` | `{}` |

### Component Versions

| Name | Description | Type | Default |
|------|-------------|------|---------|
| metrics_server_version | Version of metrics server to install | `string` | `"3.11.0"` |
| cluster_autoscaler_version | Version of cluster autoscaler to install | `string` | `"9.29.0"` |
| load_balancer_controller_version | Version of AWS Load Balancer Controller | `string` | `"1.6.2"` |
| load_balancer_controller_policy_version | Version of AWS Load Balancer Controller policy | `string` | `"v2.7.2"` |

### Configuration Objects

#### Cluster Autoscaler Configuration

```hcl
cluster_autoscaler_config = {
  scale_down_delay_after_add           = optional(string, "10m")     # Delay before scaling down after scale up
  scale_down_unneeded_time            = optional(string, "10m")     # Time before scaling down unneeded nodes
  scale_down_utilization_threshold    = optional(string, "0.5")     # Utilization threshold for scale down
  skip_nodes_with_local_storage       = optional(bool, true)        # Skip nodes with local storage
  skip_nodes_with_system_pods         = optional(bool, true)        # Skip nodes with system pods
}
```

#### Metrics Server Configuration

```hcl
metrics_server_config = {
  kubelet_insecure_tls                = optional(bool, true)                                        # Use insecure TLS
  kubelet_preferred_address_types     = optional(list(string), ["InternalIP", "ExternalIP", "Hostname"])  # Address types
}
```

#### Namespace Configuration

```hcl
namespaces = [
  {
    name        = string                    # Namespace name
    labels      = optional(map(string), {}) # Kubernetes labels
    annotations = optional(map(string), {}) # Kubernetes annotations
  }
]
```

## Outputs

| Name | Description |
|------|-------------|
| created_namespaces | List of created namespaces with names and UIDs |
| metrics_server | Metrics server installation information |
| cluster_autoscaler | Cluster autoscaler information including IAM role ARN |
| load_balancer_controller | Load balancer controller information including IAM role ARN |
| component_status | Status summary of all components |
| service_account_annotations | Service account annotations for IRSA |

### Detailed Output Structures

#### Component Status Output

```hcl
component_status = {
  metrics_server            = bool    # Installation status
  cluster_autoscaler        = bool    # Installation status
  load_balancer_controller  = bool    # Installation status
  namespaces_count         = number  # Number of created namespaces
  oidc_provider_created    = bool    # OIDC provider creation status
}
```

#### Service Account Annotations Output

```hcl
service_account_annotations = {
  cluster_autoscaler = {
    "eks.amazonaws.com/role-arn" = "arn:aws:iam::ACCOUNT:role/CLUSTER-cluster-autoscaler"
  }
  load_balancer_controller = {
    "eks.amazonaws.com/role-arn" = "arn:aws:iam::ACCOUNT:role/CLUSTER-alb-controller"
  }
}
```

## Component Details

### Metrics Server

**Purpose**: Collects resource metrics from kubelets and exposes them through the Kubernetes API

**Features**:

- Resource metrics for pods and nodes
- Enables Horizontal Pod Autoscaler (HPA)
- Configurable kubelet communication settings
- Resource requests: 100m CPU, 200Mi memory

**Configuration Options**:

- TLS settings for kubelet communication
- Preferred address types for kubelet discovery

### Cluster Autoscaler

**Purpose**: Automatically adjusts the number of nodes in a cluster based on pod scheduling requirements

**Features**:

- Automatic node group scaling
- Configurable scale-down policies
- Integration with AWS Auto Scaling Groups
- IRSA-enabled service account

**IAM Permissions**:

- Auto Scaling Group management
- EC2 instance and launch template describe
- Instance termination capabilities

**Key Settings**:

- Scale down delay: 10 minutes (configurable)
- Utilization threshold: 50% (configurable)
- Skips nodes with local storage and system pods

### AWS Load Balancer Controller

**Purpose**: Manages AWS Application Load Balancers (ALB) and Network Load Balancers (NLB) for Kubernetes services

**Features**:

- Automatic ALB/NLB provisioning
- Advanced traffic routing
- Integration with AWS services
- Support for Kubernetes Ingress resources

**IAM Permissions**:

- EC2 and ELB management
- Target group and security group management
- Route53 integration for DNS
- WAF integration capabilities

**Benefits**:

- Cost-effective load balancing
- Advanced routing capabilities
- Native AWS integration
- High performance and availability

## Security Considerations

### IAM Roles and Policies

Each component uses dedicated IAM roles with minimal required permissions:

#### Cluster Autoscaler IAM Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:DescribeInstanceTypes"
      ],
      "Resource": "*"
    }
  ]
}
```

### OIDC Trust Relationships

Service accounts use OIDC trust relationships for secure role assumption:

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
          "oidc.eks.REGION.amazonaws.com/id/OIDCID:sub": "system:serviceaccount:kube-system:cluster-autoscaler",
          "oidc.eks.REGION.amazonaws.com/id/OIDCID:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

## Integration Examples

### With Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### With AWS Load Balancer Controller

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-app-ingress
  namespace: production
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /health
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app-service
            port:
              number: 80
```

## Monitoring and Observability

### Metrics Collection

The metrics server enables comprehensive cluster monitoring:

```bash
# Check metrics server status
kubectl get deployment metrics-server -n kube-system

# View node metrics
kubectl top nodes

# View pod metrics
kubectl top pods --all-namespaces

# Check HPA status
kubectl get hpa --all-namespaces
```

### Cluster Autoscaler Monitoring

```bash
# Check cluster autoscaler logs
kubectl logs -n kube-system deployment/cluster-autoscaler

# View cluster autoscaler events
kubectl get events -n kube-system --field-selector involvedObject.name=cluster-autoscaler

# Check node group scaling activity
aws autoscaling describe-scaling-activities --auto-scaling-group-name <asg-name>
```

### Load Balancer Controller Monitoring

```bash
# Check controller status
kubectl get deployment aws-load-balancer-controller -n kube-system

# View controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Check ingress resources
kubectl get ingress --all-namespaces

# View ALB status in AWS
aws elbv2 describe-load-balancers
```

## Troubleshooting

### Common Issues

1. **Metrics Server Not Starting**

   ```bash
   # Check kubelet TLS settings
   kubectl describe pod -n kube-system -l k8s-app=metrics-server
   
   # Verify node readiness
   kubectl get nodes
   ```

2. **Cluster Autoscaler Not Scaling**

   ```bash
   # Check autoscaler logs
   kubectl logs -n kube-system deployment/cluster-autoscaler
   
   # Verify node group tags
   aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].Tags'
   
   # Check pending pods
   kubectl get pods --all-namespaces --field-selector=status.phase=Pending
   ```

3. **Load Balancer Controller Issues**

   ```bash
   # Check service account annotations
   kubectl describe serviceaccount aws-load-balancer-controller -n kube-system
   
   # Verify IAM role permissions
   aws iam get-role --role-name <cluster-name>-alb-controller
   
   # Check ingress events
   kubectl describe ingress <ingress-name> -n <namespace>
   ```

### Debugging Commands

```bash
# Check all component status
kubectl get deployments -n kube-system

# View service account roles
kubectl get serviceaccounts -n kube-system -o yaml

# Check OIDC provider
aws iam list-openid-connect-providers

# Verify cluster autoscaler configuration
kubectl get configmap cluster-autoscaler-status -n kube-system -o yaml

# Check load balancer controller webhook
kubectl get validatingwebhookconfigurations aws-load-balancer-webhook
```

## Prerequisites

1. **EKS Cluster**: Existing EKS cluster with OIDC provider
2. **Node Groups**: At least one node group for component scheduling
3. **VPC Configuration**: Proper subnet and security group setup
4. **IAM Permissions**: Permissions to create IAM roles and policies
5. **Helm Provider**: Terraform Helm provider configured
6. **Kubernetes Provider**: Terraform Kubernetes provider configured

## Version Compatibility

| Module Version | Terraform | AWS Provider | Helm Provider | Kubernetes Provider |
|---------------|-----------|--------------|---------------|-------------------|
| 1.x.x         | >= 1.0    | >= 4.0       | >= 2.0        | >= 2.0            |

## Best Practices

1. **Component Ordering**: Install metrics server first, then other components
2. **Resource Limits**: Configure appropriate resource requests and limits
3. **Version Pinning**: Pin component versions for predictable deployments
4. **Monitoring**: Implement comprehensive monitoring for all components
5. **Security**: Use least privilege IAM policies
6. **Testing**: Test autoscaling behavior in development environments
7. **Updates**: Regularly update component versions
8. **Backup**: Document configuration for disaster recovery

## Contributing

When contributing to this module:

1. Test all components together and individually
2. Verify IRSA integration works correctly
3. Update version compatibility matrix
4. Test in multiple AWS regions
5. Ensure backward compatibility

## License

This module is provided under the MIT License. See LICENSE file for details.
