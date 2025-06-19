# Create ECR repositories
resource "aws_ecr_repository" "repos" {
  for_each             = { for repo in var.ecr_repositories : repo.name => repo }
  name                 = "${var.general_tags.Project}/${each.value.name}"
  image_tag_mutability = each.value.image_tag_mutability
  force_delete = true

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  tags = var.general_tags
}

# Apply lifecycle policies - iterate over variable data directly
resource "aws_ecr_lifecycle_policy" "repos" {
  for_each = { 
    for repo in var.ecr_repositories : repo.name => repo 
    if lookup(repo, "lifecycle_policy_rules", null) != null
  }

  repository = aws_ecr_repository.repos[each.key].name
  
  policy = jsonencode({
    rules = [
      for rule in each.value.lifecycle_policy_rules : {
        rulePriority = rule.rulePriority
        description  = rule.description
        selection = {
          tagStatus     = rule.tagStatus
          tagPrefixList = rule.tagPrefixList
          countType     = rule.countType
          countNumber   = rule.countNumber
        }
        action = {
          type = rule.action_type
        }
      }
    ]
  })
}
