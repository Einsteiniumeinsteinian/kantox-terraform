# terraform/modules/parameter-store/main.tf
resource "aws_ssm_parameter" "parameters" {
  for_each = var.parameters

  name        = "/${var.general_tags.Project}/${var.general_tags.Environment}/${each.key}"
  description = each.value.description
  type        = each.value.type
  value       = each.value.value

  tags = merge(var.general_tags, {
    Name        = "/${var.general_tags.Project}/${var.general_tags.Environment}/${each.key}"
    Parameter   = each.key
  })
}
