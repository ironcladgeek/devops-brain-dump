# aws-eks/variables.tf
variable "project" {
  description = "Project name"
  type        = string
  default     = "devops-brain-dump"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.32"
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
