# modules/eks-node-groups/outputs.tf

output "node_groups" {
  description = "EKS node groups"
  value       = aws_eks_node_group.main
}

output "node_group_arns" {
  description = "ARNs of the EKS node groups"
  value = {
    for k, v in aws_eks_node_group.main : k => v.arn
  }
}

output "node_group_status" {
  description = "Status of the EKS node groups"
  value = {
    for k, v in aws_eks_node_group.main : k => v.status
  }
}

output "node_role_arn" {
  description = "IAM role ARN for the EKS node groups"
  value       = aws_iam_role.node_group.arn
}

output "launch_template_ids" {
  description = "Launch template IDs for the node groups"
  value = {
    for k, v in aws_launch_template.node_group : k => v.id
  }
}

output "launch_template_versions" {
  description = "Latest launch template versions for the node groups"
  value = {
    for k, v in aws_launch_template.node_group : k => v.latest_version
  }
}

output "amis_used" {
  value = {
    for k, v in data.aws_ami.eks_worker : k => {
      id   = v.id
      name = v.name
    }
  }
}