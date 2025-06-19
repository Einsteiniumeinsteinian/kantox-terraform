# modules/security-groups/outputs.tf

output "security_groups" {
  description = "Map of security group names to their attributes"
  value = var.create_security_groups ? {
    for name, sg in aws_security_group.security_groups : name => {
      id          = sg.id
      arn         = sg.arn
      name        = sg.name
      description = sg.description
      vpc_id      = sg.vpc_id
      tags        = sg.tags
    }
  } : {}
}

output "security_group_ids" {
  description = "Map of security group names to their IDs"
  value = local.security_group_ids
}

output "security_group_names" {
  description = "Map of original names to final names (with prefix/suffix)"
  value = local.sg_names
}

output "created_ingress_rules" {
  description = "Map of created ingress rules"
  value = {
    for k, v in aws_security_group_rule.ingress : k => {
      id                = v.id
      type              = v.type
      from_port         = v.from_port
      to_port           = v.to_port
      protocol          = v.protocol
      security_group_id = v.security_group_id
    }
  }
}

output "created_egress_rules" {
  description = "Map of created egress rules"
  value = {
    for k, v in aws_security_group_rule.egress : k => {
      id                = v.id
      type              = v.type
      from_port         = v.from_port
      to_port           = v.to_port
      protocol          = v.protocol
      security_group_id = v.security_group_id
    }
  }
}