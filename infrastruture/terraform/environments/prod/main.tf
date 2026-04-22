terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "food-delivery-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  environment   = "prod"
  cluster_name  = "${var.project_name}-${local.environment}"

  common_tags = {
    Environment  = local.environment
    Project      = var.project_name
    ManagedBy    = "Terraform"
    CreatedAt    = timestamp()
    CostCenter   = "Production"
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  project_name          = var.project_name
  environment           = local.environment
  common_tags           = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security_group"

  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr
  project_name = var.project_name
  environment  = local.environment
  common_tags  = local.common_tags
}

# EC2 Module
module "ec2" {
  source = "../../modules/ec2"

  project_name              = var.project_name
  environment               = local.environment
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  master_security_group_id  = module.security_groups.master_security_group_id
  worker_security_group_id  = module.security_groups.worker_security_group_id
  
  master_node_count        = var.prod_master_node_count
  worker_node_count        = var.prod_worker_node_count
  master_instance_type     = var.prod_master_instance_type
  worker_instance_type     = var.prod_worker_instance_type
  cluster_name             = local.cluster_name
  kubernetes_version       = var.kubernetes_version
  
  common_tags              = local.common_tags
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  project_name          = var.project_name
  environment           = local.environment
  private_subnet_ids    = module.vpc.private_subnet_ids
  rds_security_group_id = module.security_groups.rds_security_group_id
  
  allocated_storage         = var.prod_db_allocated_storage
  instance_class            = var.prod_db_instance_class
  postgres_version          = var.postgres_version
  database_name             = var.database_name
  db_username               = var.db_username
  db_password               = var.db_password
  backup_retention_period   = var.prod_backup_retention_period
  multi_az                  = var.prod_multi_az
  
  common_tags               = local.common_tags
}

# ElastiCache Module
module "elasticache" {
  source = "../../modules/elasticache"

  project_name                  = var.project_name
  environment                   = local.environment
  private_subnet_ids            = module.vpc.private_subnet_ids
  elasticache_security_group_id = module.security_groups.elasticache_security_group_id
  
  redis_version             = var.redis_version
  node_type                 = var.prod_redis_node_type
  num_cache_nodes           = var.prod_redis_num_cache_nodes
  automatic_failover_enabled = var.prod_redis_automatic_failover
  
  common_tags               = local.common_tags
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  project_name            = var.project_name
  environment             = local.environment
  vpc_id                  = module.vpc.vpc_id
  public_subnet_ids       = module.vpc.public_subnet_ids
  alb_security_group_id   = module.security_groups.alb_security_group_id
  worker_instance_ids     = module.ec2.worker_instance_ids
  certificate_arn         = var.certificate_arn
  enable_deletion_protection = true
  
  common_tags             = local.common_tags
}

# Outputs
output "cluster_info" {
  description = "Cluster information"
  value = {
    cluster_name          = local.cluster_name
    vpc_id                = module.vpc.vpc_id
    master_instance_ids   = module.ec2.master_instance_ids
    worker_instance_ids   = module.ec2.worker_instance_ids
    rds_endpoint          = module.rds.db_instance_endpoint
    redis_endpoint        = module.elasticache.redis_endpoint
    alb_dns_name          = module.alb.alb_dns_name
  }
}
