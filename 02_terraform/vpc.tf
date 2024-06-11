provider "aws" {
  alias  = "region"
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"
  name = "${var.project_name}-vpc"
  cidr = "192.168.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["192.168.48.0/20", "192.168.64.0/20", "192.168.80.0/20"]
  public_subnets  = ["192.168.0.0/20", "192.168.16.0/20", "192.168.32.0/20"]

  enable_nat_gateway   = true
  enable_dns_support   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "owned" 
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "owned"
  }
}
