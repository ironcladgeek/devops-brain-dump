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
