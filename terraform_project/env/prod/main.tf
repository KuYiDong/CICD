terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.23.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "6.5.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs               = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]              # ALB, NAT GW
  private_subnets   = ["10.0.10.0/24", "10.0.20.0/24"]      

  enable_nat_gateway       = true
  one_nat_gateway_per_az   = false
  enable_dns_support       = true
  enable_dns_hostnames     = true
  single_nat_gateway       = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.1"

  role_name = "aws-load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "my-cluster"
  kubernetes_version = "1.33"

  addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
  }

  # Optional
  endpoint_public_access = true
  endpoint_private_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = module.vpc.vpc_id
  # 노드가 배치될 서브넷
  subnet_ids               = module.vpc.private_subnets
  # ENI 가 배치될 서브넷 (하나만 있어도 연결에는 문제 안됨)
  control_plane_subnet_ids = module.vpc.private_subnets


  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    group-a = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
      subnet_ids   = [module.vpc.private_subnets[0]]
    }

    group-b = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]
      min_size     = 1
      max_size     = 2
      desired_size = 1
      subnet_ids   = [module.vpc.private_subnets[1]] 
  }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
