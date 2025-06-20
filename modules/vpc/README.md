# AWS VPC Terraform Module

This Terraform module creates a comprehensive AWS Virtual Private Cloud (VPC) infrastructure with public and private subnets, internet connectivity, and NAT gateways. It provides a standardized, scalable, and secure networking foundation for AWS workloads with multi-AZ support and flexible configuration options.

## Features

- **Complete VPC Infrastructure**: VPC, subnets, internet gateway, NAT gateways, and routing
- **Multi-AZ Deployment**: Distribute resources across multiple availability zones for high availability
- **Public and Private Subnets**: Separate network tiers for different security requirements
- **Internet Connectivity**: Internet gateway for public subnet access
- **NAT Gateway Integration**: Secure outbound internet access for private subnets
- **DNS Support**: Enable DNS hostnames and resolution within the VPC
- **Standardized Naming**: Consistent naming convention with environment, project, and optional prefix/suffix
- **Flexible Tagging**: Comprehensive tagging strategy with resource-specific optional tags
- **Scalable Design**: Support for multiple subnets and availability zones

## Network Architecture

The module creates a standard 3-tier network architecture:

```architecture
Internet
    │
    ▼
Internet Gateway
    │
    ▼
┌─────────────────────────────────────────────────────────────────┐
│                         VPC (10.0.0.0/16)                      │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │  Public Subnet  │  │  Public Subnet  │  │  Public Subnet  │  │
│  │   10.0.1.0/24   │  │   10.0.2.0/24   │  │   10.0.3.0/24   │  │
│  │      AZ-a       │  │      AZ-b       │  │      AZ-c       │  │
│  └─────────┬───────┘  └─────────┬───────┘  └─────────┬───────┘  │
│            │                    │                    │          │
│       NAT Gateway          NAT Gateway          NAT Gateway     │
│            │                    │                    │          │
│  ┌─────────▼───────┐  ┌─────────▼───────┐  ┌─────────▼───────┐  │
│  │ Private Subnet  │  │ Private Subnet  │  │ Private Subnet  │  │
│  │  10.0.11.0/24   │  │  10.0.12.0/24   │  │  10.0.13.0/24   │  │
│  │      AZ-a       │  │      AZ-b       │  │      AZ-c       │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Example

```hcl
module "vpc" {
  source = "./modules/vpc"

  network = {
    cidr_block     = "10.0.0.0/16"
    Azs            = ["us-west-2a", "us-west-2b", "us-west-2c"]
    public_subnet  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnet = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
    create_default_sg = true
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

### Development Environment

```hcl
module "dev_vpc" {
  source = "./modules/vpc"

  network = {
    cidr_block     = "10.1.0.0/16"
    Azs            = ["us-west-2a", "us-west-2b"]
    public_subnet  = ["10.1.1.0/24", "10.1.2.0/24"]
    private_subnet = ["10.1.11.0/24", "10.1.12.0/24"]
    create_default_sg = true
  }

  name_prefix = "dev"

  general_tags = {
    Environment = "development"
    Project     = "myapp"
    Owner       = "dev-team"
    Team        = "development"
    ManagedBy   = "terraform"
  }

  optional_tags = {
    vpc = {
      "CostCenter" = "development"
      "AutoShutdown" = "enabled"
    }
    public_subnets = {
      "Type" = "public"
      "InternetAccess" = "direct"
    }
    private_subnets = {
      "Type" = "private"
      "InternetAccess" = "nat"
    }
  }
}
```

### Production Multi-Environment Setup

```hcl
# Production VPC
module "production_vpc" {
  source = "./modules/vpc"

  network = {
    cidr_block     = "10.0.0.0/16"
    Azs            = ["us-west-2a", "us-west-2b", "us-west-2c"]
    public_subnet  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnet = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
    create_default_sg = true
  }

  name_prefix = "prod"

  general_tags = {
    Environment = "production"
    Project     = "ecommerce"
    Owner       = "platform-team"
    Team        = "infrastructure"
    ManagedBy   = "terraform"
  }

  optional_tags = {
    vpc = {
      "CostCenter"   = "production"
      "Backup"       = "required"
      "Compliance"   = "pci-dss"
      "Monitoring"   = "enhanced"
    }
    public_subnets = {
      "Tier"         = "web"
      "LoadBalancer" = "alb"
      "ExternalAccess" = "true"
    }
    private_subnets = {
      "Tier"         = "application"
      "DatabaseAccess" = "true"
      "ExternalAccess" = "nat-only"
    }
    internet_gateway = {
      "Purpose"      = "public-access"
      "Monitoring"   = "cloudwatch"
    }
  }
}

# Staging VPC
module "staging_vpc" {
  source = "./modules/vpc"

  network = {
    cidr_block     = "10.1.0.0/16"
    Azs            = ["us-west-2a", "us-west-2b"]
    public_subnet  = ["10.1.1.0/24", "10.1.2.0/24"]
    private_subnet = ["10.1.11.0/24", "10.1.12.0/24"]
    create_default_sg = true
  }

  name_prefix = "staging"

  general_tags = {
    Environment = "staging"
    Project     = "ecommerce"
    Owner       = "platform-team"
    Team        = "infrastructure"
    ManagedBy   = "terraform"
  }

  optional_tags = {
    vpc = {
      "CostCenter"   = "staging"
      "AutoShutdown" = "nights-weekends"
    }
    public_subnets = {
      "Tier" = "web"
      "TestEnvironment" = "true"
    }
    private_subnets = {
      "Tier" = "application"
      "TestEnvironment" = "true"
    }
  }
}
```

### Large Scale Enterprise Setup

```hcl
module "enterprise_vpc" {
  source = "./modules/vpc"

  network = {
    cidr_block = "10.0.0.0/16"
    Azs = [
      "us-west-2a", 
      "us-west-2b", 
      "us-west-2c", 
      "us-west-2d"
    ]
    public_subnet = [
      "10.0.1.0/24",   # AZ-a Public (ALB, NAT)
      "10.0.2.0/24",   # AZ-b Public (ALB, NAT)
      "10.0.3.0/24",   # AZ-c Public (ALB, NAT)
      "10.0.4.0/24"    # AZ-d Public (ALB, NAT)
    ]
    private_subnet = [
      "10.0.11.0/24",  # AZ-a Application Tier
      "10.0.12.0/24",  # AZ-b Application Tier
      "10.0.13.0/24",  # AZ-c Application Tier
      "10.0.14.0/24"   # AZ-d Application Tier
    ]
    create_default_sg = true
  }

  name_prefix = "enterprise"
  name_suffix = "v2"

  general_tags = {
    Environment = "production"
    Project     = "enterprise-platform"
    Owner       = "cloud-platform-team"
    Team        = "infrastructure"
    ManagedBy   = "terraform"
  }

  optional_tags = {
    vpc = {
      "CostCenter"     = "infrastructure"
      "Compliance"     = "sox-pci-hipaa"
      "BackupRequired" = "true"
      "DR"            = "cross-region"
      "VPCFlowLogs"   = "enabled"
    }
    public_subnets = {
      "Tier"              = "dmz"
      "LoadBalancerType"  = "application"
      "ExternalFacing"    = "true"
      "SecurityLevel"     = "high"
    }
    private_subnets = {
      "Tier"              = "application"
      "SecurityLevel"     = "high"
      "DatabaseAccess"    = "restricted"
      "InternetAccess"    = "nat-gateway"
    }
    internet_gateway = {
      "Purpose"           = "external-connectivity"
      "MonitoringLevel"   = "enhanced"
      "SecurityGroup"     = "restricted"
    }
  }
}
```

### Microservices Architecture

```hcl
module "microservices_vpc" {
  source = "./modules/vpc"

  network = {
    cidr_block = "10.2.0.0/16"
    Azs = ["us-west-2a", "us-west-2b", "us-west-2c"]
    
    # Public subnets for load balancers and NAT gateways
    public_subnet = [
      "10.2.1.0/24",    # Public AZ-a (ALB, API Gateway)
      "10.2.2.0/24",    # Public AZ-b (ALB, API Gateway)
      "10.2.3.0/24"     # Public AZ-c (ALB, API Gateway)
    ]
    
    # Private subnets for microservices
    private_subnet = [
      "10.2.11.0/24",   # Services AZ-a (User Service, Order Service)
      "10.2.12.0/24",   # Services AZ-b (Payment Service, Inventory Service)
      "10.2.13.0/24"    # Services AZ-c (Notification Service, Analytics Service)
    ]
    
    create_default_sg = true
  }

  name_prefix = "microservices"

  general_tags = {
    Environment = "production"
    Project     = "microservices-platform"
    Owner       = "backend-team"
    Team        = "development"
    ManagedBy   = "terraform"
  }

  optional_tags = {
    vpc = {
      "Architecture"   = "microservices"
      "ServiceMesh"    = "istio"
      "Container"      = "eks"
      "Monitoring"     = "prometheus"
    }
    public_subnets = {
      "Purpose"        = "ingress-gateway"
      "LoadBalancer"   = "application"
      "ApiGateway"     = "enabled"
    }
    private_subnets = {
      "Purpose"        = "microservices"
      "ContainerRuntime" = "fargate"
      "ServiceDiscovery" = "eks"
    }
  }
}
```

### Public-Only VPC (Static Website/CDN)

```hcl
module "public_vpc" {
  source = "./modules/vpc"

  network = {
    cidr_block     = "10.3.0.0/16"
    Azs            = ["us-west-2a", "us-west-2b"]
    public_subnet  = ["10.3.1.0/24", "10.3.2.0/24"]
    private_subnet = []  # No private subnets needed
    create_default_sg = true
  }

  general_tags = {
    Environment = "production"
    Project     = "static-website"
    Owner       = "frontend-team"
    Team        = "development"
    ManagedBy   = "terraform"
  }

  optional_tags = {
    vpc = {
      "Purpose"        = "static-hosting"
      "ContentDelivery" = "cloudfront"
    }
    public_subnets = {
      "Purpose"        = "web-hosting"
      "ContentType"    = "static"
    }
  }
}
```

## Inputs

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| network | Network configuration object | `object` |
| general_tags | Global required tags for all resources | `object` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| optional_tags | Optional tags per resource type | `object` | `{}` |
| name_prefix | Optional name prefix for all resource Name tags | `string` | `""` |
| name_suffix | Optional name suffix for all resource Name tags | `string` | `""` |

### Network Configuration Object

```hcl
network = {
  cidr_block        = string        # VPC CIDR block (e.g., "10.0.0.0/16")
  Azs               = list(string)  # List of availability zones
  private_subnet    = list(string)  # List of private subnet CIDR blocks
  public_subnet     = list(string)  # List of public subnet CIDR blocks
  create_default_sg = bool          # Whether to create default security group
}
```

### General Tags Object

```hcl
general_tags = {
  Environment = string                          # Environment (e.g., "production", "staging")
  Owner       = string                          # Owner of the resources
  Project     = string                          # Project name
  Team        = string                          # Team responsible
  ManagedBy   = optional(string, "terraform")   # Management tool
}
```

### Optional Tags Object

```hcl
optional_tags = {
  vpc              = optional(map(string), {})  # Additional VPC tags
  public_subnets   = optional(map(string), {})  # Additional public subnet tags
  private_subnets  = optional(map(string), {})  # Additional private subnet tags
  internet_gateway = optional(map(string), {})  # Additional internet gateway tags
}
```

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the created VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |

### Output Examples

```hcl
# VPC ID
vpc_id = "vpc-0123456789abcdef0"

# Public Subnet IDs
public_subnet_ids = [
  "subnet-0123456789abcdef0",
  "subnet-abcdef0123456789",
  "subnet-456789abcdef0123"
]

# Private Subnet IDs
private_subnet_ids = [
  "subnet-789abcdef0123456",
  "subnet-def0123456789abc",
  "subnet-0123456789def456"
]
```

## Network Design Considerations

### CIDR Block Planning

#### Recommended CIDR Blocks by Environment

| Environment | VPC CIDR | Use Case |
|-------------|----------|----------|
| Development | 10.1.0.0/16 | Small development workloads |
| Staging | 10.2.0.0/16 | Pre-production testing |
| Production | 10.0.0.0/16 | Production workloads |
| DR/Backup | 10.10.0.0/16 | Disaster recovery region |

#### Subnet Sizing Guidelines

| Subnet Type | Recommended Size | Use Case |
|-------------|------------------|----------|
| Public Subnets | /24 (254 hosts) | Load balancers, NAT gateways, bastion hosts |
| Private Subnets | /24 to /20 | Application servers, databases, microservices |
| Database Subnets | /24 (254 hosts) | Dedicated database tier |

### Availability Zone Strategy

```hcl
# Minimum 2 AZs for high availability
Azs = ["us-west-2a", "us-west-2b"]

# Recommended 3 AZs for maximum availability
Azs = ["us-west-2a", "us-west-2b", "us-west-2c"]

# Enterprise 4+ AZs for critical workloads
Azs = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"]
```

### Subnet Distribution Patterns

#### Pattern 1: Even Distribution

```hcl
network = {
  cidr_block = "10.0.0.0/16"
  Azs = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnet = [
    "10.0.1.0/24",   # AZ-a
    "10.0.2.0/24",   # AZ-b
    "10.0.3.0/24"    # AZ-c
  ]
  private_subnet = [
    "10.0.11.0/24",  # AZ-a
    "10.0.12.0/24",  # AZ-b
    "10.0.13.0/24"   # AZ-c
  ]
}
```

#### Pattern 2: Tiered Architecture

```hcl
network = {
  cidr_block = "10.0.0.0/16"
  Azs = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnet = [
    "10.0.1.0/24",   # Web tier AZ-a
    "10.0.2.0/24",   # Web tier AZ-b
    "10.0.3.0/24"    # Web tier AZ-c
  ]
  private_subnet = [
    "10.0.11.0/24",  # App tier AZ-a
    "10.0.12.0/24",  # App tier AZ-b
    "10.0.13.0/24"   # App tier AZ-c
  ]
}
```

## Security Best Practices

### Network Segmentation

1. **Public Subnets**: Only for internet-facing resources
   - Application Load Balancers
   - NAT Gateways
   - Bastion Hosts (if needed)

2. **Private Subnets**: For application and database tiers
   - Application servers
   - Databases
   - Internal services

### Route Table Security

The module automatically creates secure routing:

```hcl
# Public Route Table
# 0.0.0.0/0 -> Internet Gateway (direct internet access)

# Private Route Tables (per AZ)
# 0.0.0.0/0 -> NAT Gateway (outbound internet via NAT)
```

### DNS Configuration

```hcl
# DNS settings enabled by default
enable_dns_hostnames = true
enable_dns_support   = true
```

## Advanced Configurations

### VPC Peering Preparation

```hcl
module "main_vpc" {
  source = "./modules/vpc"

  network = {
    cidr_block     = "10.0.0.0/16"  # Non-overlapping CIDR
    Azs            = ["us-west-2a", "us-west-2b"]
    public_subnet  = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnet = ["10.0.11.0/24", "10.0.12.0/24"]
    create_default_sg = true
  }

  general_tags = var.common_tags

  optional_tags = {
    vpc = {
      "PeeringReady" = "true"
      "CIDR" = "10.0.0.0/16"
    }
  }
}

module "shared_services_vpc" {
  source = "./modules/vpc"

  network = {
    cidr_block     = "10.1.0.0/16"  # Non-overlapping CIDR
    Azs            = ["us-west-2a", "us-west-2b"]
    public_subnet  = ["10.1.1.0/24", "10.1.2.0/24"]
    private_subnet = ["10.1.11.0/24", "10.1.12.0/24"]
    create_default_sg = true
  }

  general_tags = var.common_tags

  optional_tags = {
    vpc = {
      "Purpose" = "shared-services"
      "PeeringReady" = "true"
      "CIDR" = "10.1.0.0/16"
    }
  }
}
```

### Transit Gateway Integration

```hcl
module "vpc" {
  source = "./modules/vpc"

  network = {
    cidr_block     = "10.0.0.0/16"
    Azs            = ["us-west-2a", "us-west-2b", "us-west-2c"]
    public_subnet  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnet = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
    create_default_sg = true
  }

  general_tags = var.common_tags

  optional_tags = {
    vpc = {
      "TransitGateway" = "enabled"
      "RouteManagement" = "centralized"
    }
  }
}

# Transit Gateway attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  subnet_ids         = module.vpc.private_subnet_ids
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = module.vpc.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-tgw-attachment"
  })
}
```

## Monitoring and Observability

### VPC Flow Logs

```hcl
resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-vpc-flow-logs"
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flowlogs"
  retention_in_days = 30

  tags = var.common_tags
}
```

### CloudWatch Metrics

```hcl
resource "aws_cloudwatch_metric_alarm" "nat_gateway_bandwidth" {
  count = length(module.vpc.private_subnet_ids)

  alarm_name          = "nat-gateway-bandwidth-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BytesOutToDestination"
  namespace           = "AWS/NATGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000000000"  # 1GB
  alarm_description   = "This metric monitors NAT gateway bandwidth usage"

  dimensions = {
    NatGatewayId = aws_nat_gateway.nat[count.index].id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

## Cost Optimization

### NAT Gateway Costs

NAT Gateways are charged hourly plus data processing fees:

```hcl
# Cost-optimized: Single NAT Gateway (reduces availability)
resource "aws_nat_gateway" "single" {
  count             = 1
  subnet_id         = aws_subnet.public_subnet[0].id
  connectivity_type = "public"
  allocation_id     = aws_eip.eip[0].id
}

# High availability: NAT Gateway per AZ (recommended for production)
resource "aws_nat_gateway" "per_az" {
  count             = length(var.network.private_subnet)
  subnet_id         = aws_subnet.public_subnet[count.index].id
  connectivity_type = "public"
  allocation_id     = aws_eip.eip[count.index].id
}
```

### Cost Monitoring

```hcl
resource "aws_budgets_budget" "vpc_costs" {
  name         = "${var.project}-vpc-budget"
  budget_type  = "COST"
  limit_amount = "100"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filters {
    service = [
      "Amazon Virtual Private Cloud",
      "Amazon Elastic Compute Cloud - Network"
    ]
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

1. **CIDR Block Conflicts**

   ```bash
   Error: InvalidVpc.Range: The CIDR '10.0.0.0/16' conflicts with another subnet
   ```

   **Solutions**:
   - Use non-overlapping CIDR blocks
   - Check existing VPCs and subnets in the region
   - Plan CIDR allocation across environments

2. **Subnet CIDR Outside VPC Range**

   ```bash
   Error: InvalidSubnet.Range: The CIDR '10.1.0.0/24' is invalid for vpc 'vpc-xxx'
   ```

   **Solution**: Ensure all subnet CIDRs are within the VPC CIDR block:

   ```hcl
   # VPC CIDR: 10.0.0.0/16
   # Valid subnet CIDRs: 10.0.0.0/24 to 10.0.255.0/24
   ```

3. **Insufficient IP Addresses**

   ```bash
   Error: InsufficientFreeAddressesInSubnet
   ```

   **Solutions**:
   - Use larger subnet CIDR blocks (/23, /22)
   - Distribute resources across multiple subnets
   - Monitor IP address usage

4. **NAT Gateway Creation Failed**

   ```bash
   Error: InvalidAllocationID.NotFound
   ```

   **Solution**: Ensure Elastic IP allocation exists before NAT Gateway creation

5. **Route Table Association Errors**

   ```bash
   Error: Resource.AlreadyAssociated
   ```

   **Solution**: Check for existing route table associations

### Debugging Commands

```bash
# List VPCs and their CIDR blocks
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock,State]' --output table

# List subnets in a VPC
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-12345678" --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,State]' --output table

# Check route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-12345678" --query 'RouteTables[*].[RouteTableId,Routes[*].[DestinationCidrBlock,GatewayId,NatGatewayId]]' --output table

# Check NAT Gateway status
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=vpc-12345678" --query 'NatGateways[*].[NatGatewayId,State,SubnetId]' --output table

# Check internet gateway attachment
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=vpc-12345678" --query 'InternetGateways[*].[InternetGatewayId,Attachments[*].State]' --output table

# Verify DNS settings
aws ec2 describe-vpc-attribute --vpc-id vpc-12345678 --attribute enableDnsSupport
aws ec2 describe-vpc-attribute --vpc-id vpc-12345678 --attribute enableDnsHostnames
```

### Network Connectivity Testing

```bash
# Test internet connectivity from private subnet (via NAT Gateway)
# From instance in private subnet:
curl -I http://checkip.amazonaws.com

# Test connectivity between subnets
# From instance in one subnet to another:
ping 10.0.12.100

# Check DNS resolution
nslookup google.com
dig @169.254.169.253 vpc.internal
```

## Performance Optimization

### Subnet Placement Strategy

1. **Application Load Balancers**: Deploy in public subnets across multiple AZs
2. **Auto Scaling Groups**: Distribute across private subnets in multiple AZs
3. **Databases**: Use dedicated database subnets or private subnets
4. **Cache Layers**: Co-locate with application tier for low latency

### Network Performance

```hcl
# Enhanced networking for EC2 instances
resource "aws_instance" "web" {
  count                  = length(module.vpc.private_subnet_ids)
  ami                    = var.ami_id
  instance_type          = "c5n.large"  # Enhanced networking supported
  subnet_id              = module.vpc.private_subnet_ids[count.index]
  vpc_security_group_ids = [aws_security_group.web.id]

  # Enable enhanced networking
  ena_support    = true
  sriov_net_support = "simple"

  tags = merge(var.common_tags, {
    Name = "web-${count.index + 1}"
  })
}
```

### Bandwidth Considerations

- **NAT Gateway**: Up to 45 Gbps bandwidth
- **Internet Gateway**: No bandwidth limits
- **Cross-AZ Traffic**: Data transfer charges apply
- **Same-AZ Traffic**: No additional charges

## Security Hardening

### Network ACLs (Additional Security Layer)

```hcl
# Custom Network ACL for private subnets
resource "aws_network_acl" "private" {
  vpc_id = module.vpc.vpc_id

  # Allow inbound HTTP from public subnets
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 80
    to_port    = 80
  }

  # Allow inbound HTTPS from public subnets
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 443
    to_port    = 443
  }

  # Allow all outbound traffic
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.common_tags, {
    Name = "${var.project}-private-nacl"
  })
}

# Associate with private subnets
resource "aws_network_acl_association" "private" {
  count          = length(module.vpc.private_subnet_ids)
  network_acl_id = aws_network_acl.private.id
  subnet_id      = module.vpc.private_subnet_ids[count.index]
}
```

### VPC Security Groups

```hcl
# Default security group rules (restrictive)
resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc_id

  # No ingress rules (deny all inbound)
  # No egress rules (deny all outbound)

  tags = merge(var.common_tags, {
    Name = "${var.project}-default-sg"
  })
}
```

## Disaster Recovery

### Cross-Region VPC Setup

```hcl
# Primary region VPC
module "primary_vpc" {
  source = "./modules/vpc"

  network = {
    cidr_block     = "10.0.0.0/16"
    Azs            = ["us-west-2a", "us-west-2b", "us-west-2c"]
    public_subnet  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnet = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
    create_default_sg = true
  }

  general_tags = merge(var.common_tags, {
    Region = "primary"
    DR     = "source"
  })
}

# DR region VPC
provider "aws" {
  alias  = "dr"
  region = "us-east-1"
}

module "dr_vpc" {
  source = "./modules/vpc"
  
  providers = {
    aws = aws.dr
  }

  network = {
    cidr_block     = "10.1.0.0/16"  # Different CIDR for DR
    Azs            = ["us-east-1a", "us-east-1b", "us-east-1c"]
    public_subnet  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
    private_subnet = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
    create_default_sg = true
  }

  general_tags = merge(var.common_tags, {
    Region = "dr"
    DR     = "target"
  })
}
```

### Backup and Recovery

```hcl
# VPC configuration backup
resource "local_file" "vpc_config_backup" {
  content = jsonencode({
    vpc_id             = module.vpc.vpc_id
    vpc_cidr           = var.network.cidr_block
    public_subnet_ids  = module.vpc.public_subnet_ids
    private_subnet_ids = module.vpc.private_subnet_ids
    availability_zones = var.network.Azs
    created_date      = timestamp()
  })
  
  filename = "backups/vpc-config-${var.environment}-${formatdate("YYYY-MM-DD", timestamp())}.json"
}
```

## Compliance and Governance

### Tagging Strategy

```hcl
# Comprehensive tagging for compliance
general_tags = {
  Environment       = "production"
  Project          = "ecommerce"
  Owner            = "platform-team"
  Team             = "infrastructure"
  ManagedBy        = "terraform"
  CostCenter       = "engineering"
  Compliance       = "pci-dss"
  DataClassification = "confidential"
  BackupRequired   = "true"
  MonitoringLevel  = "enhanced"
}

optional_tags = {
  vpc = {
    "aws:cloudformation:stack-name" = var.stack_name
    "backup:frequency"              = "daily"
    "security:classification"       = "internal"
  }
}
```

### Resource Naming Standards

```hcl
# Naming convention: {prefix}-{environment}-{project}-{resource}-{suffix}
# Examples:
# - prod-production-ecommerce-vpc-v2
# - staging-staging-microservices-public_subnet:1/3-v1
# - dev-development-api-private_subnet:2/2
```

## Prerequisites

1. **AWS Account**: Valid AWS account with VPC creation permissions
2. **IAM Permissions**: EC2 VPC, subnet, and routing permissions
3. **Availability Zones**: At least 2 AZs available in the target region
4. **CIDR Planning**: Non-overlapping CIDR blocks for different environments
5. **Terraform Version**: >= 1.0 for optional variable support

## Version Compatibility

| Module Version | Terraform | AWS Provider | Features |
|---------------|-----------|--------------|----------|
| 1.x.x         | >= 1.0    | >= 4.0       | Full functionality |
| 1.x.x         | >= 0.14   | >= 3.0       | Basic functionality |

## Best Practices Summary

### Network

1. **Multi-AZ Deployment**: Always use at least 2 AZs for high availability
2. **Subnet Sizing**: Plan subnet sizes based on expected resource count
3. **CIDR Planning**: Use non-overlapping CIDR blocks across environments
4. **Public/Private Separation**: Keep application tiers in private subnets

### Security

1. **Default Deny**: Use restrictive default security groups
2. **Network ACLs**: Implement additional network-level security
3. **VPC Flow Logs**: Enable comprehensive network monitoring
4. **DNS Security**: Enable DNS features for internal resolution

### Operational Excellence

1. **Standardized Naming**: Use consistent naming conventions
2. **Comprehensive Tagging**: Implement detailed tagging strategy
3. **Documentation**: Document network architecture and IP allocation
4. **Monitoring**: Implement network performance and cost monitoring

### Cost Management

1. **NAT Gateway Strategy**: Balance cost vs. availability requirements
2. **Resource Right-Sizing**: Choose appropriate subnet sizes
3. **Cross-AZ Traffic**: Minimize unnecessary cross-AZ data transfer
4. **Regular Reviews**: Monitor and optimize network costs

## Contributing

When contributing to this module:

1. Test with multiple subnet configurations
2. Verify cross-AZ deployment patterns
3. Test with different CIDR block sizes
4. Ensure proper resource dependencies
5. Update documentation for new features
6. Test integration with common AWS services
7. Validate in multiple AWS regions

## License

This module is provided under the MIT License. See LICENSE file for details.
