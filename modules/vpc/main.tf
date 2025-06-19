locals {
  prefix_dash = var.name_prefix != "" ? "${var.name_prefix}-" : ""
  suffix_dash = var.name_suffix != "" ? "-${var.name_suffix}" : ""
  network_base_name = "${local.prefix_dash}${var.general_tags.Environment}-${var.general_tags.Project}${local.suffix_dash}"

}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = var.network.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    {
      Name = "${local.network_base_name}-vpc"
    },
    var.general_tags,
    var.optional_tags.vpc
  )
}

## Subnets
# Public subnet
resource "aws_subnet" "public_subnet" {
  count                   = var.network.public_subnet == null ? 0 : length(var.network.public_subnet)
  vpc_id                  = aws_vpc.main.id
  availability_zone       = element(var.network.Azs, count.index)
  cidr_block              = element(var.network.public_subnet, count.index)
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "${local.network_base_name}-public_subnet:${count.index + 1}/${length(var.network.public_subnet)}"
    },
    var.general_tags,
    var.optional_tags.public_subnets
  )
}

resource "aws_subnet" "private_subnet" {
  count                   = var.network.private_subnet == null ? 0 : length(var.network.private_subnet)
  vpc_id                  = aws_vpc.main.id
  availability_zone       = element(var.network.Azs, count.index)
  cidr_block              = element(var.network.private_subnet, count.index)
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "${local.network_base_name}-private_subnet:${count.index + 1}/${length(var.network.private_subnet)}"
    },
    var.general_tags,
    var.optional_tags.private_subnets
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${local.network_base_name}-igw"
    },
    var.general_tags,
    var.optional_tags.internet_gateway
  )
}

## NAT Gateways
# Elastic IP
resource "aws_eip" "eip" {
  count = var.network.private_subnet == null ? 0 : length(var.network.private_subnet)

  tags = merge(
    {
      Name = "${local.network_base_name}-eip:${count.index + 1}/${length(var.network.private_subnet)}"
    },
    var.general_tags,
  )
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  count             = aws_eip.eip == null ? 0 : length(var.network.private_subnet)
  subnet_id         = aws_subnet.public_subnet[count.index].id
  connectivity_type = "public"
  allocation_id     = aws_eip.eip[count.index].id

  depends_on = [
    aws_internet_gateway.igw,
    aws_eip.eip
  ]

  tags = merge(
    {
      Name = "${local.network_base_name}-nat:${count.index + 1}/${length(var.network.private_subnet)}"
    },
    var.general_tags,
  )
}

## Routing
# Public Route Table
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    {
      Name = "${local.network_base_name}-public-rtb"
    },
    var.general_tags,
  )
}

# Public Route Table Association
resource "aws_route_table_association" "public_rtba" {
  count          = length(var.network.public_subnet)
  route_table_id = aws_route_table.public_rtb.id
  subnet_id      = aws_subnet.public_subnet[count.index].id
}

# Private Route Table
resource "aws_route_table" "private_rtb" {
  count  = length(var.network.private_subnet)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = merge(
    {
      Name = "${local.network_base_name}-private-rtb:${count.index + 1}/${length(var.network.private_subnet)}"
    },
    var.general_tags,
  )
}

# Private Route Table Association
resource "aws_route_table_association" "private_rtba" {
  count          = var.network.private_subnet == null ? 0 : length(var.network.private_subnet)
  route_table_id = aws_route_table.private_rtb[count.index].id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}
