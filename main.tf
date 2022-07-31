locals {
  vpc_region_primary            = "us-west-2"
  hvn_region_primary            = "us-west-2"
  cluster_id_primary            = "primary"
  hvn_id_primary                = "us-west-2"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.43"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.18.0"
    }
  }
}

provider "aws" {
  region = local.vpc_region_primary
  assume_role {
    role_arn = var.role_arn
  }
}

resource "hcp_hvn" "main" {
  hvn_id         = local.hvn_id_primary
  cloud_provider = "aws"
  region         = local.hvn_region_primary
  cidr_block     = "172.25.32.0/20"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "main"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "aws_ec2_consul_client" {
  source  = "./vault-ec2-benchmark-host/"

  subnet_id                = module.vpc.public_subnets[0]
  security_group_id        = module.aws_hcp_vault.security_group_id
  allowed_ssh_cidr_blocks  = ["0.0.0.0/0"]
  allowed_http_cidr_blocks = ["0.0.0.0/0"]
}