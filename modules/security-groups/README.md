# AWS Security Groups Terraform Module

This Terraform module creates and manages AWS Security Groups with a flexible, comprehensive approach. It supports both creating new security groups and managing rules for existing ones, with standardized naming conventions, validation checks, and advanced rule management capabilities.

## Features

- **Flexible Creation**: Create new security groups or manage existing ones
- **Standardized Naming**: Consistent naming convention with environment, project, and optional prefix/suffix
- **Advanced Rule Management**: Comprehensive ingress and egress rule configuration
- **Rule Validation**: Built-in validation for configuration consistency
- **IPv6 Support**: Full support for IPv6 CIDR blocks
- **Self-Referencing Rules**: Support for security group self-referencing
- **Cross-Group References**: Support for source security group references
- **Default Egress Control**: Configurable default egress rule management
- **Comprehensive Tagging**: Automatic tagging with project, environment, and custom metadata
- **Lifecycle Management**: Proper resource lifecycle handling with create_before_destroy

## Security Group Naming Convention

The module follows a standardized naming pattern:

```
{prefix}-{environment}-{project}-{sg-name}-{suffix}
```

**Examples:**
- `production-myapp-web-sg` (without prefix/suffix)
- `company-production-myapp-api-v2-sg` (with prefix and suffix)
- `staging-ecommerce-database-sg` (staging environment)

## Usage

### Basic Example

```hcl
module "security_groups" {
  source = "./modules/security-groups"

  vpc_id                 = "vpc-12345678"
  create_security_groups = true

  security_groups = [
    {
      name        = "web"
      description = "Security group for web servers"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTP access from internet"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS access from internet"
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "All outbound traffic"
        }
      ]
    }
  ]

  general_tags = {
    Environment = "production"
    Project     = "myapp"
    Owner       = "platform-team"
    Team        = "infrastructure"
    ManagedBy   = "terraform"
  }
}
```

### Complete Multi-Tier Architecture

```hcl
module "app_security_groups" {
  source = "./modules/security-groups"

  vpc_id                 = module.vpc.vpc_id
  create_security_groups = true

  security_groups = [
    # Application Load Balancer Security Group
    {
      name        = "alb"
      description = "Security group for Application Load Balancer"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTP access from internet"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS access from internet"
        }
      ]
      egress_rules = [
        {
          from_port                = 80
          to_port                  = 80
          protocol                 = "tcp"
          source_security_group_id = null  # Will reference web SG after creation
          description              = "HTTP to web servers"
        }
      ]
    },

    # Web Tier Security Group
    {
      name        = "web"
      description = "Security group for web servers"
      ingress_rules = [
        {
          from_port                = 80
          to_port                  = 80
          protocol                 = "tcp"
          source_security_group_id = null  # Will reference ALB SG after creation
          description              = "HTTP from load balancer"
        },
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/8"]
          description = "SSH access from private networks"
        }
      ]
      egress_rules = [
        {
          from_port                = 3306
          to_port                  = 3306
          protocol                 = "tcp"
          source_security_group_id = null  # Will reference database SG after creation
          description              = "MySQL to database"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS to external APIs"
        }
      ]
    },

    # Database Tier Security Group
    {
      name        = "database"
      description = "Security group for database servers"
      ingress_rules = [
        {
          from_port                = 3306
          to_port                  = 3306
          protocol                 = "tcp"
          source_security_group_id = null  # Will reference web SG after creation
          description              = "MySQL from web servers"
        },
        {
          from_port                = 3306
          to_port                  = 3306
          protocol                 = "tcp"
          source_security_group_id = null  # Will reference admin SG after creation
          description              = "MySQL from admin tools"
        }
      ]
      egress_rules = []  # No outbound access needed
    },

    # Admin/Bastion Security Group
    {
      name        = "admin"
      description = "Security group for administrative access"
      ingress_rules = [
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = ["203.0.113.0/24"]  # Your office IP range
          description = "SSH access from office"
        }
      ]
      egress_rules = [
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/8"]
          description = "SSH to private instances"
        },
        {
          from_port                = 3306
          to_port                  = 3306
          protocol                 = "tcp"
          source_security_group_id = null  # Will reference database SG after creation
          description              = "MySQL for database administration"
        }
      ]
    },

    # Redis/ElastiCache Security Group
    {
      name        = "redis"
      description = "Security group for Redis cluster"
      ingress_rules = [
        {
          from_port                = 6379
          to_port                  = 6379
          protocol                 = "tcp"
          source_security_group_id = null  # Will reference web SG after creation
          description              = "Redis access from web servers"
        }
      ]
      egress_rules = []  # No outbound access needed
    },

    # EKS Worker Nodes Security Group
    {
      name        = "eks-workers"
      description = "Security group for EKS worker nodes"
      ingress_rules = [
        {
          from_port   = 1025
          to_port     = 65535
          protocol    = "tcp"
          self        = true
          description = "Node to node communication"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/8"]
          description = "HTTPS from control plane"
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "All outbound traffic"
        }
      ]
    }
  ]

  name_prefix = "company"
  name_suffix = "v1"

  general_tags = {
    Environment = "production"
    Project     = "ecommerce"
    Owner       = "platform-team"
    Team        = "infrastructure"
    ManagedBy   = "terraform"
  }

  optional_tags = {
    security_groups = {
      "CostCenter" = "engineering"
      "Compliance" = "pci-dss"
    }
  }
}
```

### Managing Existing Security Groups

```hcl
module "existing_sg_rules" {
  source = "./modules/security-groups"

  create_security_groups = false
  existing_security_groups = {
    web      = "sg-0123456789abcdef0"
    database = "sg-abcdef0123456789"
    admin    = "sg-456789abcdef0123"
  }

  security_groups = [
    {
      name        = "web"
      description = "Managed web security group"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTP access"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS access"
        }
      ]
      egress_rules = [
        {
          from_port   = 3306
          to_port     = 3306
          protocol    = "tcp"
          source_security_group_id = "sg-abcdef0123456789"  # Reference database SG
          description = "MySQL to database"
        }
      ]
    }
  ]

  general_tags = {
    Environment = "production"
    Project     = "legacy-app"
    Owner       = "platform-team"
    Team        = "infrastructure"
    ManagedBy   = "terraform"
  }
}
```

### Microservices Architecture

```hcl
module "microservices_security" {
  source = "./modules/security-groups"

  vpc_id                 = var.vpc_id
  create_security_groups = true

  security_groups = [
    # API Gateway Security Group
    {
      name        = "api-gateway"
      description = "Security group for API Gateway"
      ingress_rules = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS API access"
        }
      ]
      egress_rules = [
        {
          from_port   = 8080
          to_port     = 8090
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/8"]
          description = "HTTP to microservices"
        }
      ]
    },

    # User Service Security Group
    {
      name        = "user-service"
      description = "Security group for user microservice"
      ingress_rules = [
        {
          from_port                = 8080
          to_port                  = 8080
          protocol                 = "tcp"
          source_security_group_id = null  # API Gateway SG
          description              = "HTTP from API Gateway"
        },
        {
          from_port   = 8080
          to_port     = 8080
          protocol    = "tcp"
          self        = true
          description = "Service-to-service communication"
        }
      ]
      egress_rules = [
        {
          from_port                = 5432
          to_port                  = 5432
          protocol                 = "tcp"
          source_security_group_id = null  # Database SG
          description              = "PostgreSQL access"
        }
      ]
    },

    # Order Service Security Group
    {
      name        = "order-service"
      description = "Security group for order microservice"
      ingress_rules = [
        {
          from_port                = 8081
          to_port                  = 8081
          protocol                 = "tcp"
          source_security_group_id = null  # API Gateway SG
          description              = "HTTP from API Gateway"
        },
        {
          from_port   = 8081
          to_port     = 8081
          protocol    = "tcp"
          self        = true
          description = "Service-to-service communication"
        }
      ]
      egress_rules = [
        {
          from_port                = 5432
          to_port                  = 5432
          protocol                 = "tcp"
          source_security_group_id = null  # Database SG
          description              = "PostgreSQL access"
        },
        {
          from_port                = 8080
          to_port                  = 8080
          protocol                 = "tcp"
          source_security_group_id = null  # User Service SG
          description              = "HTTP to user service"
        }
      ]
    },

    # Message Queue Security Group
    {
      name        = "message-queue"
      description = "Security group for message queue (RabbitMQ/SQS)"
      ingress_rules = [
        {
          from_port   = 5672
          to_port     = 5672
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/8"]
          description = "AMQP access from services"
        },
        {
          from_port   = 15672
          to_port     = 15672
          protocol    = "tcp"
          cidr_blocks = ["10.0.1.0/24"]  # Admin subnet
          description = "RabbitMQ management interface"
        }
      ]
      egress_rules = []
    }
  ]

  general_tags = {
    Environment = "production"
    Project     = "microservices"
    Owner       = "development-team"
    Team        = "backend"
    ManagedBy   = "terraform"
  }
}
```

### IPv6 and Advanced Rules

```hcl
module "ipv6_security_groups" {
  source = "./modules/security-groups"

  vpc_id                 = var.vpc_id
  create_security_groups = true

  security_groups = [
    {
      name        = "web-ipv6"
      description = "Web security group with IPv6 support"
      ingress_rules = [
        {
          from_port        = 80
          to_port          = 80
          protocol         = "tcp"
          cidr_blocks      = ["0.0.0.0/0"]
          ipv6_cidr_blocks = ["::/0"]
          description      = "HTTP access from IPv4 and IPv6"
        },
        {
          from_port        = 443
          to_port          = 443
          protocol         = "tcp"
          cidr_blocks      = ["0.0.0.0/0"]
          ipv6_cidr_blocks = ["::/0"]
          description      = "HTTPS access from IPv4 and IPv6"
        },
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = ["203.0.113.0/24"]
          description = "SSH from office IPv4"
        }
      ]
      egress_rules = [
        {
          from_port        = 0
          to_port          = 0
          protocol         = "-1"
          cidr_blocks      = ["0.0.0.0/0"]
          ipv6_cidr_blocks = ["::/0"]
          description      = "All outbound traffic IPv4 and IPv6"
        }
      ]
    }
  ]

  general_tags = var.common_tags
}
```

## Inputs

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| security_groups | List of security groups to create or configure | `list(object)` |
| general_tags | Required base tags (must include Project and Environment) | `object` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| vpc_id | VPC ID where security groups will be created | `string` | `null` |
| create_security_groups | Whether to create new security groups | `bool` | `true` |
| existing_security_groups | Map of existing security group IDs | `map(string)` | `{}` |
| create_ingress_rules | Whether to create ingress rules | `bool` | `true` |
| create_egress_rules | Whether to create egress rules | `bool` | `true` |
| name_prefix | Optional name prefix | `string` | `""` |
| name_suffix | Optional name suffix | `string` | `""` |
| enable_default_egress | Whether to keep the default egress rule | `bool` | `false` |
| optional_tags | Optional tags per resource type | `object` | `{}` |

### Security Groups Object Structure

```hcl
security_groups = [
  {
    name        = string  # Security group name (used in final naming)
    description = string  # Security group description
    
    ingress_rules = optional(list(object({
      from_port                = number                    # Start port number
      to_port                  = number                    # End port number
      protocol                 = string                    # Protocol (tcp, udp, icmp, or -1 for all)
      cidr_blocks             = optional(list(string))     # IPv4 CIDR blocks
      ipv6_cidr_blocks        = optional(list(string))     # IPv6 CIDR blocks
      source_security_group_id = optional(string)          # Source security group ID
      self                    = optional(bool, false)      # Self-referencing rule
      description             = string                     # Rule description
    })), [])
    
    egress_rules = optional(list(object({
      from_port                = number                    # Start port number
      to_port                  = number                    # End port number
      protocol                 = string                    # Protocol (tcp, udp, icmp, or -1 for all)
      cidr_blocks             = optional(list(string))     # IPv4 CIDR blocks
      ipv6_cidr_blocks        = optional(list(string))     # IPv6 CIDR blocks
      source_security_group_id = optional(string)          # Destination security group ID
      self                    = optional(bool, false)      # Self-referencing rule
      description             = string                     # Rule description
    })), [])
  }
]
```

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
| security_groups | Complete security group information with IDs, ARNs, and metadata |
| security_group_ids | Map of security group names to their IDs |
| security_group_names | Map of original names to final names (with prefix/suffix) |
| created_ingress_rules | Map of created ingress rules with details |
| created_egress_rules | Map of created egress rules with details |

### Output Structures

#### Security Groups Output
```hcl
security_groups = {
  web = {
    id          = "sg-0123456789abcdef0"
    arn         = "arn:aws:ec2:us-west-2:123456789012:security-group/sg-0123456789abcdef0"
    name        = "production-myapp-web-sg"
    description = "Security group for web servers"
    vpc_id      = "vpc-12345678"
    tags        = {
      Environment = "production"
      Project     = "myapp"
      Name        = "production-myapp-web-sg"
    }
  }
}
```

#### Security Group IDs Output
```hcl
security_group_ids = {
  web      = "sg-0123456789abcdef0"
  database = "sg-abcdef0123456789"
  admin    = "sg-456789abcdef0123"
}
```

## Rule Types and Protocols

### Common Protocols

| Protocol | Description | Common Ports |
|----------|-------------|--------------|
| `tcp` | Transmission Control Protocol | 80 (HTTP), 443 (HTTPS), 22 (SSH), 3306 (MySQL) |
| `udp` | User Datagram Protocol | 53 (DNS), 123 (NTP), 161 (SNMP) |
| `icmp` | Internet Control Message Protocol | N/A (ping, traceroute) |
| `-1` | All protocols | All ports |

### Port Ranges

```hcl
# Single port
from_port = 80
to_port   = 80

# Port range
from_port = 8000
to_port   = 8999

# All ports
from_port = 0
to_port   = 0
protocol  = "-1"
```

### Rule Sources and Destinations

1. **CIDR Blocks** (IPv4/IPv6)
   ```hcl
   cidr_blocks      = ["0.0.0.0/0"]        # All IPv4
   ipv6_cidr_blocks = ["::/0"]             # All IPv6
   cidr_blocks      = ["10.0.0.0/8"]       # Private networks
   cidr_blocks      = ["203.0.113.0/24"]   # Specific subnet
   ```

2. **Security Group References**
   ```hcl
   source_security_group_id = "sg-0123456789abcdef0"  # Specific SG
   source_security_group_id = module.other_sg.security_group_ids.web  # From another module
   ```

3. **Self-Referencing**
   ```hcl
   self = true  # Allow traffic within the same security group
   ```

## Security Best Practices

### Principle of Least Privilege

1. **Specific Ports**: Use specific port ranges instead of allowing all ports
   ```hcl
   # Good
   from_port = 443
   to_port   = 443
   protocol  = "tcp"
   
   # Avoid
   from_port = 0
   to_port   = 0
   protocol  = "-1"
   ```

2. **Restricted Sources**: Use specific CIDR blocks instead of 0.0.0.0/0 when possible
   ```hcl
   # Good for internal services
   cidr_blocks = ["10.0.0.0/8"]
   
   # Good for office access
   cidr_blocks = ["203.0.113.0/24"]
   
   # Use sparingly for public services
   cidr_blocks = ["0.0.0.0/0"]
   ```

3. **Security Group References**: Use security group references for inter-service communication
   ```hcl
   # Better than CIDR blocks for internal communication
   source_security_group_id = module.web_sg.security_group_ids.web
   ```

### Default Egress Management

```hcl
# Remove default egress (allow all outbound)
enable_default_egress = false

# Define specific egress rules
egress_rules = [
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS to external APIs only"
  }
]
```

### Rule Documentation

Always include meaningful descriptions:

```hcl
description = "HTTP access from internet"           # Good
description = "HTTPS to payment gateway API"       # Good
description = "MySQL access from web tier"         # Good
description = "Port 80"                            # Poor
```

## Advanced Configurations

### Cross-Security Group References

When security groups reference each other, create them in dependency order or use data sources:

```hcl
# Method 1: Separate rule creation
module "security_groups" {
  source = "./modules/security-groups"
  
  # Create SGs without cross-references first
  security_groups = [
    {
      name = "web"
      description = "Web servers"
      ingress_rules = []  # Rules added separately
      egress_rules = []
    },
    {
      name = "database"
      description = "Database servers"
      ingress_rules = []
      egress_rules = []
    }
  ]
}

# Method 2: Add rules with references
resource "aws_security_group_rule" "web_to_db" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.security_groups.security_group_ids.database
  security_group_id        = module.security_groups.security_group_ids.web
  description              = "MySQL access to database"
}
```

### Conditional Rules

```hcl
variable "enable_ssh_access" {
  description = "Enable SSH access"
  type        = bool
  default     = false
}

locals {
  ssh_rules = var.enable_ssh_access ? [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "SSH access from private networks"
    }
  ] : []
}

module "security_groups" {
  source = "./modules/security-groups"
  
  security_groups = [
    {
      name          = "web"
      description   = "Web servers"
      ingress_rules = concat(
        [
          {
            from_port   = 80
            to_port     = 80
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
            description = "HTTP access"
          }
        ],
        local.ssh_rules
      )
    }
  ]
}
```

### Environment-Specific Rules

```hcl
locals {
  base_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP access"
    }
  ]
  
  debug_rules = var.environment == "development" ? [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "Debug port for development"
    }
  ] : []
}

module "security_groups" {
  source = "./modules/security-groups"
  
  security_groups = [
    {
      name          = "web"
      description   = "Web servers"
      ingress_rules = concat(local.base_rules, local.debug_rules)
    }
  ]
}
```

## Integration Examples

### With EKS Cluster

```hcl
module "eks_security_groups" {
  source = "./modules/security-groups"

  vpc_id                 = module.vpc.vpc_id
  create_security_groups = true

  security_groups = [
    {
      name        = "eks-control-plane"
      description = "EKS control plane security group"
      ingress_rules = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = [module.vpc.vpc_cidr_block]
          description = "HTTPS access from VPC"
        }
      ]
      egress_rules = [
        {
          from_port   = 1025
          to_port     = 65535
          protocol    = "tcp"
          cidr_blocks = [module.vpc.vpc_cidr_block]
          description = "Communication with worker nodes"
        }
      ]
    }
  ]

  general_tags = var.common_tags
}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    security_group_ids = [module.eks_security_groups.security_group_ids.eks-control-plane]
    subnet_ids         = module.vpc.private_subnet_ids
  }
}
```

### With RDS Database

```hcl
module "database_security" {
  source = "./modules/security-groups"

  vpc_id                 = var.vpc_id
  create_security_groups = true

  security_groups = [
    {
      name        = "rds-mysql"
      description = "Security group for RDS MySQL database"
      ingress_rules = [
        {
          from_port                = 3306
          to_port                  = 3306
          protocol                 = "tcp"
          source_security_group_id = module.app_security.security_group_ids.web
          description              = "MySQL access from web servers"
        }
      ]
      egress_rules = []  # No outbound access needed
    }
  ]

  general_tags = var.common_tags
}

resource "aws_db_instance" "mysql" {
  identifier = "${var.project}-${var.environment}-mysql"
  
  vpc_security_group_ids = [module.database_security.security_group_ids.rds-mysql]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  # Other RDS configuration...
}
```

### With Application Load Balancer

```hcl
module "alb_security" {
  source = "./modules/security-groups"

  vpc_id                 = var.vpc_id
  create_security_groups = true

  security_groups = [
    {
      name        = "alb-public"
      description = "Security group for public Application Load Balancer"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTP from internet"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS from internet"
        }
      ]
      egress_rules = [
        {
          from_port                = 80
          to_port                  = 80
          protocol                 = "tcp"
          source_security_group_id = module.app_security.security_group_ids.web
          description              = "HTTP to web servers"
        }
      ]
    }
  ]

  general_tags = var.common_tags
}

resource "aws_lb" "main" {
  name               = "${var.project}-${var.environment}-alb"
  load_balancer_type = "application"
  security_groups    = [module.alb_security.security_group_ids.alb-public]
  subnets            = var.public_subnet_ids
}
```

## Monitoring and Auditing

### CloudTrail Integration

Monitor security group changes and rule modifications:

```hcl
resource "aws_cloudtrail" "security_audit" {
  name           = "${var.project}-security-audit"
  s3_bucket_name = aws_s3_bucket.cloudtrail.bucket

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    
    data_resource {
      type   = "AWS::EC2::SecurityGroup"
      values = ["arn:aws:ec2:*:*:security-group/*"]
    }
  }

  tags = var.common_tags
}
```

### VPC Flow Logs

Monitor traffic patterns and security group effectiveness:

```hcl
resource "aws_flow_log" "security_monitoring" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.security.arn
  traffic_type    = "ALL"
  vpc_id          = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.project}-security-flow-logs"
  })
}

resource "aws_cloudwatch_log_group" "security" {
  name              = "/aws/vpc/flowlogs"
  retention_in_days = 30
  
  tags = var.common_tags
}
```

### Security Group Compliance Monitoring

```hcl
resource "aws_config_configuration_recorder" "security" {
  name     = "${var.project}-security-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_config_rule" "security_group_ssh_check" {
  name = "${var.project}-sg-ssh-check"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder.security]
}
```

## Troubleshooting

### Common Issues

1. **Security Group Rule Conflicts**
   ```bash
   # Check existing rules
   aws ec2 describe-security-groups --group-ids sg-0123456789abcdef0
   
   # Verify rule dependencies
   aws ec2 describe-security-group-references --group-id sg-0123456789abcdef0
   ```

2. **VPC ID Missing Error**
   ```
   Error: vpc_id is required when create_security_groups is true
   ```
   **Solution**: Ensure `vpc_id` is provided when creating new security groups:
   ```hcl
   vpc_id = module.vpc.vpc_id  # or data.aws_vpc.existing.id
   ```

3. **Existing Security Group Not Found**
   ```
   Error: Missing security groups in existing_security_groups: web, database
   ```
   **Solution**: Provide all referenced security group IDs:
   ```hcl
   existing_security_groups = {
     web      = "sg-0123456789abcdef0"
     database = "sg-abcdef0123456789"
   }
   ```

4. **Circular Dependencies**
   ```
   Error: Cycle: aws_security_group_rule.web_to_db, aws_security_group_rule.db_to_web
   ```
   **Solution**: Create security groups first, then add cross-references:
   ```hcl
   # Step 1: Create security groups without cross-references
   # Step 2: Add rules with references separately
   ```

5. **Rule Duplication**
   ```
   Error: InvalidGroup.Duplicate: the specified rule "peer: sg-xxx, TCP, from port: 80, to port: 80, ALLOW" already exists
   ```
   **Solution**: Check for duplicate rules in your configuration

### Debugging Commands

```bash
# List all security groups in VPC
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=vpc-12345678"

# Get specific security group details
aws ec2 describe-security-groups --group-ids sg-0123456789abcdef0

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-0123456789abcdef0 --query 'SecurityGroups[0].IpPermissions'

# Find security groups by name
aws ec2 describe-security-groups --filters "Name=group-name,Values=production-myapp-web-sg"

# Check which resources are using a security group
aws ec2 describe-network-interfaces --filters "Name=group-id,Values=sg-0123456789abcdef0"

# Verify VPC Flow Logs
aws ec2 describe-flow-logs --filter "Name=resource-id,Values=vpc-12345678"
```

### Validation Checks

The module includes built-in validation checks:

1. **VPC ID Required**: When creating security groups, VPC ID must be provided
2. **Existing Security Groups**: When not creating security groups, existing IDs must be provided
3. **Missing Security Groups**: All referenced security groups must exist in the mapping
4. **Non-empty Names**: Security group names and descriptions cannot be empty

## Performance Considerations

### Rule Limits

AWS has limits on security group rules:
- **Rules per security group**: 60 inbound, 60 outbound (soft limit)
- **Security groups per network interface**: 5 (hard limit)
- **Referenced security groups**: 5 per rule

### Optimization Strategies

1. **Consolidate Similar Rules**
   ```hcl
   # Instead of multiple single-port rules
   # Use port ranges where possible
   {
     from_port = 8000
     to_port   = 8099
     protocol  = "tcp"
     cidr_blocks = ["10.0.0.0/8"]
     description = "Microservices port range"
   }
   ```

2. **Use Security Group References**
   ```hcl
   # More efficient than CIDR blocks for dynamic environments
   source_security_group_id = module.web_sg.security_group_ids.web
   ```

3. **Minimize Cross-References**
   ```hcl
   # Design security groups to minimize circular dependencies
   # Use hierarchical approach: ALB -> Web -> Database
   ```

## Cost Optimization

### Security Group Management

- **No Direct Costs**: Security groups themselves are free
- **Indirect Costs**: Complex rules can impact network performance
- **Management Overhead**: Too many security groups increase operational complexity

### Best Practices for Cost-Effective Security

1. **Standardize Security Groups**: Reuse common security group patterns
2. **Automate Management**: Use Terraform for consistent deployment
3. **Monitor Usage**: Regular audits to remove unused security groups
4. **Document Thoroughly**: Clear descriptions reduce troubleshooting time

## Migration Strategies

### From Manual to Terraform

1. **Import Existing Security Groups**
   ```bash
   # Import existing security group
   terraform import module.security_groups.aws_security_group.security_groups[\"web\"] sg-0123456789abcdef0
   ```

2. **Gradual Migration**
   ```hcl
   # Phase 1: Import existing SGs, don't create rules
   create_security_groups = false
   create_ingress_rules   = false
   create_egress_rules    = false
   
   # Phase 2: Enable rule management
   create_ingress_rules = true
   create_egress_rules  = true
   
   # Phase 3: Full management
   create_security_groups = true
   ```

3. **Blue-Green Security Groups**
   ```hcl
   # Create new security groups alongside existing ones
   name_suffix = "v2"
   
   # Test with new security groups
   # Switch traffic gradually
   # Remove old security groups
   ```

## Prerequisites

1. **AWS Account**: Valid AWS account with EC2/VPC permissions
2. **VPC**: Existing VPC for security group creation
3. **IAM Permissions**: Ability to create and manage security groups and rules
4. **Terraform Version**: >= 1.5 for validation checks
5. **AWS Provider**: >= 4.0 for latest security group features

## Version Compatibility

| Module Version | Terraform | AWS Provider | Features |
|---------------|-----------|--------------|----------|
| 1.x.x         | >= 1.5    | >= 4.0       | Validation checks, IPv6 support |
| 1.x.x         | >= 1.0    | >= 3.0       | Basic functionality |

## Best Practices Summary

### Security
1. **Principle of Least Privilege**: Minimal required access
2. **Specific Rules**: Avoid broad port ranges and CIDR blocks
3. **Rule Documentation**: Clear, meaningful descriptions
4. **Regular Audits**: Periodic security group reviews

### Operational
1. **Standardized Naming**: Consistent naming conventions
2. **Environment Separation**: Clear environment boundaries
3. **Version Control**: All changes through Terraform
4. **Documentation**: Comprehensive rule documentation

### Performance
1. **Rule Optimization**: Efficient rule design
2. **Dependency Management**: Minimize circular dependencies
3. **Monitoring**: Track security group usage and effectiveness

### Cost Management
1. **Resource Efficiency**: Remove unused security groups
2. **Automation**: Reduce manual management overhead
3. **Standardization**: Reuse common patterns

## Contributing

When contributing to this module:
1. Follow security best practices for all examples
2. Test with multiple security group configurations
3. Validate cross-referencing scenarios
4. Ensure backward compatibility
5. Update documentation for new features
6. Test in multiple AWS regions
7. Verify IPv6 compatibility

## License

This module is provided under the MIT License. See LICENSE file for details.