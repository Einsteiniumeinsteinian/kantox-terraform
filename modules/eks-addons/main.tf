# modules/eks-addons/main.tf

locals {
  prefix_dash = var.name_prefix != "" ? "${var.name_prefix}-" : ""
  suffix_dash = var.name_suffix != "" ? "-${var.name_suffix}" : ""
  cluster_base_name = "${local.prefix_dash}${var.general_tags.Environment}-${var.general_tags.Project}-${var.cluster_name}${local.suffix_dash}"

  eks_addons_map = {
    for addon in var.addons : addon.name => addon
  }
}

resource "aws_eks_addon" "addons" {
  for_each = local.eks_addons_map

  cluster_name                  = var.cluster_name
  addon_name                   = each.value.name
  configuration_values         = lookup(each.value, "configuration_values", null)
  preserve                     = lookup(each.value, "preserve", null)
  service_account_role_arn     = lookup(each.value, "service_account_role_arn", null)
  resolve_conflicts_on_update  = lookup(each.value, "resolve_conflicts_on_update", "OVERWRITE")

  tags = merge(
    var.general_tags,
    {
      Name = "${local.cluster_base_name}-addon-${each.value.name}"
    }
  )
}
