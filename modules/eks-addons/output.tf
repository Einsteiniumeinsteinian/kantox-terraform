# modules/eks-addons/outputs.tf

output "eks_addons" {
  description = "Map of EKS managed add-ons created"
  value = {
    for name, addon in aws_eks_addon.addons :
    name => addon.id
  }
}