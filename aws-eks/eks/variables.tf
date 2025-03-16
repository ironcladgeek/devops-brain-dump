# aws-eks/eks/variables.tf

variable "project" {
  description = "The project name"
  type        = string
}

variable "environment" {
  description = "The environment name"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.32"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "Private subnets"
  type        = list(string)
}

variable "eks_cluster_role_arn" {
  description = "EKS cluster IAM role ARN"
  type        = string
}

variable "eks_node_group_role_arn" {
  description = "EKS node group IAM role ARN"
  type        = string
}

variable "instance_types" {
  description = "EC2 instance types"
  type        = list(string)
  default     = ["t2.medium", "t2.large"]
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 5
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}
