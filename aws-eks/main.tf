# aws-eks/main.tf

provider "aws" {
  region = var.region
}

module "vpc" {
  source             = "./vpc"
  project            = var.project
  environment        = var.environment
  region             = var.region
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "iam" {
  source      = "./iam"
  project     = var.project
  environment = var.environment
}

module "eks" {
  source                  = "./eks"
  project                 = var.project
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  private_subnets         = module.vpc.private_subnet_ids
  eks_cluster_role_arn    = module.iam.eks_cluster_role_arn
  eks_node_group_role_arn = module.iam.eks_node_group_role_arn
  cluster_version         = var.cluster_version
  instance_types          = var.instance_types
  min_size                = var.min_size
  max_size                = var.max_size
  desired_size            = var.desired_size
}
