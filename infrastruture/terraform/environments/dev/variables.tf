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
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

# Kubernetes Variables
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

# Dev EC2 Variables
variable "dev_master_node_count" {
  description = "Number of master nodes"
  type        = number
  default     = 1
}

variable "dev_worker_node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "dev_master_instance_type" {
  description = "Master node instance type"
  type        = string
  default     = "t3.large"
}

variable "dev_worker_instance_type" {
  description = "Worker node instance type"
  type        = string
  default     = "t3.large"
}

# Dev Database Variables
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

variable "dev_db_allocated_storage" {
  description = "Allocated storage for dev DB"
  type        = number
  default     = 20
}

variable "dev_db_instance_class" {
  description = "Dev DB instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "dev_backup_retention_period" {
  description = "Dev backup retention period"
  type        = number
  default     = 3
}

variable "dev_multi_az" {
  description = "Dev Multi-AZ enabled"
  type        = bool
  default     = false
}

# Dev Cache Variables
variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "7.0"
}

variable "dev_redis_node_type" {
  description = "Dev Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "dev_redis_num_cache_nodes" {
  description = "Dev Redis number of cache nodes"
  type        = number
  default     = 1
}

variable "dev_redis_automatic_failover" {
  description = "Dev Redis automatic failover"
  type        = bool
  default     = false
}

# ALB Variables
variable "certificate_arn" {
  description = "SSL certificate ARN"
  type        = string
}
