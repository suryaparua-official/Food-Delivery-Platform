variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "food-delivery"
}

# VPC Variables
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.2.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.2.10.0/24", "10.2.11.0/24", "10.2.12.0/24"]
}

# Kubernetes Variables
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

# Production EC2 Variables
variable "prod_master_node_count" {
  description = "Number of master nodes"
  type        = number
  default     = 3
}

variable "prod_worker_node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 5
}

variable "prod_master_instance_type" {
  description = "Master node instance type"
  type        = string
  default     = "t3.xlarge"
}

variable "prod_worker_instance_type" {
  description = "Worker node instance type"
  type        = string
  default     = "t3.2xlarge"
}

# Production Database Variables
variable "database_name" {
  description = "Initial database name"
  type        = string
  default     = "fooddelivery"
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "prod_db_allocated_storage" {
  description = "Allocated storage for prod DB"
  type        = number
  default     = 500
}

variable "prod_db_instance_class" {
  description = "Prod DB instance class"
  type        = string
  default     = "db.r5.xlarge"
}

variable "prod_backup_retention_period" {
  description = "Prod backup retention period"
  type        = number
  default     = 30
}

variable "prod_multi_az" {
  description = "Prod Multi-AZ enabled"
  type        = bool
  default     = true
}

# Production Cache Variables
variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "7.0"
}

variable "prod_redis_node_type" {
  description = "Prod Redis node type"
  type        = string
  default     = "cache.r5.large"
}

variable "prod_redis_num_cache_nodes" {
  description = "Prod Redis number of cache nodes"
  type        = number
  default     = 3
}

variable "prod_redis_automatic_failover" {
  description = "Prod Redis automatic failover"
  type        = bool
  default     = true
}

# ALB Variables
variable "certificate_arn" {
  description = "SSL certificate ARN"
  type        = string
}
