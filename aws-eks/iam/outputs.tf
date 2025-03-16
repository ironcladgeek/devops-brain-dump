# aws-eks/iam/outputs.tf

output "eks_cluster_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_nodegroup_role_arn" {
  description = "EKS node group IAM role ARN"
  value       = aws_iam_role.eks_nodegroup.arn
}
