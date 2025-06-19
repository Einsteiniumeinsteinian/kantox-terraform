# modules/security-groups/main.tf

locals {
  # Conditional dashes
  prefix_dash = var.name_prefix != "" ? "${var.name_prefix}-" : ""
  suffix_dash = var.name_suffix != "" ? "-${var.name_suffix}" : ""

  # Create a map for easier reference
  security_groups_map = {
    for sg in var.security_groups : sg.name => sg
  }

  # Final SG names including env/project/prefix/suffix (only when creating new SGs)
  sg_names = var.create_security_groups ? {
    for sg_name in keys(local.security_groups_map) :
    sg_name => "${local.prefix_dash}${var.general_tags.Environment}-${var.general_tags.Project}-${sg_name}${local.suffix_dash}"
  } : {}

  # Security group IDs - either from created resources or existing ones
  security_group_ids = var.create_security_groups ? {
    for name, sg in aws_security_group.security_groups : name => sg.id
  } : var.existing_security_groups

  # Validate that all security groups in the list have corresponding IDs
  missing_security_groups = [
    for sg_name in keys(local.security_groups_map) : sg_name
    if !contains(keys(local.security_group_ids), sg_name)
  ]

  # Flatten ingress rules
  ingress_rules = var.create_ingress_rules ? flatten([
    for sg_name, sg in local.security_groups_map : [
      for idx, rule in sg.ingress_rules : {
        sg_name                  = sg_name
        rule_key                 = "${sg_name}-ingress-${idx}"
        from_port                = rule.from_port
        to_port                  = rule.to_port
        protocol                 = rule.protocol
        cidr_blocks             = rule.cidr_blocks
        ipv6_cidr_blocks        = rule.ipv6_cidr_blocks
        source_security_group_id = rule.source_security_group_id
        self                    = rule.self
        description             = rule.description
      }
    ]
  ]) : []

  # Flatten egress rules
  egress_rules = var.create_egress_rules ? flatten([
    for sg_name, sg in local.security_groups_map : [
      for idx, rule in sg.egress_rules : {
        sg_name                  = sg_name
        rule_key                 = "${sg_name}-egress-${idx}"
        from_port                = rule.from_port
        to_port                  = rule.to_port
        protocol                 = rule.protocol
        cidr_blocks             = rule.cidr_blocks
        ipv6_cidr_blocks        = rule.ipv6_cidr_blocks
        source_security_group_id = rule.source_security_group_id
        self                    = rule.self
        description             = rule.description
      }
    ]
  ]) : []
}

# Validation checks (Terraform 1.5+)
check "vpc_id_required" {
  assert {
    condition     = !var.create_security_groups || var.vpc_id != null
    error_message = "vpc_id is required when create_security_groups is true."
  }
}

check "existing_sg_required" {
  assert {
    condition     = var.create_security_groups || length(var.existing_security_groups) > 0
    error_message = "existing_security_groups must be provided when create_security_groups is false."
  }
}

check "missing_security_groups" {
  assert {
    condition     = length(local.missing_security_groups) == 0
    error_message = "Missing security groups in existing_security_groups: ${join(", ", local.missing_security_groups)}"
  }
}

# Validation using variable validation instead of null_resource
# This runs during plan phase and provides clearer error messages

# Create security groups (only if create_security_groups is true)
resource "aws_security_group" "security_groups" {
  for_each = var.create_security_groups ? local.security_groups_map : {}

  name        = local.sg_names[each.key]
  description = each.value.description
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = merge(
    {
      Name = "${local.sg_names[each.key]}-sg"
    },
    var.general_tags,
    var.optional_tags.security_groups
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Remove default egress rule if not wanted (only for created security groups)
resource "aws_security_group_rule" "revoke_default_egress" {
  for_each = var.enable_default_egress ? aws_security_group.security_groups : {}

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = each.value.id
}

# Create ingress rules
resource "aws_security_group_rule" "ingress" {
  for_each = {
    for rule in local.ingress_rules : rule.rule_key => rule
  }

  type                     = "ingress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.self == true ? null : each.value.cidr_blocks
  ipv6_cidr_blocks         = each.value.self == true ? null : each.value.ipv6_cidr_blocks
  source_security_group_id = each.value.self == true ? null : each.value.source_security_group_id
  self                     = each.value.self == true ? true : null
  description              = each.value.description
  security_group_id        = local.security_group_ids[each.value.sg_name]

  # Static depends_on - will be ignored if resources don't exist
  depends_on = [
    aws_security_group.security_groups
  ]
}

# Create egress rules
resource "aws_security_group_rule" "egress" {
  for_each = {
    for rule in local.egress_rules : rule.rule_key => rule
  }

  type                     = "egress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.self == true ? null : each.value.cidr_blocks
  ipv6_cidr_blocks         = each.value.self == true ? null : each.value.ipv6_cidr_blocks
  source_security_group_id = each.value.self == true ? null : each.value.source_security_group_id
  self                     = each.value.self == true ? true : null
  description              = each.value.description
  security_group_id        = local.security_group_ids[each.value.sg_name]

  # Static depends_on - will be ignored if resources don't exist
  depends_on = [
    aws_security_group.security_groups
  ]
}