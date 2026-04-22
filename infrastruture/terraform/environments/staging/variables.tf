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
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]
}

# Kubernetes Variables
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

# Staging EC2 Variables
variable "staging_master_node_count" {
  description = "Number of master nodes"
  type        = number
  default     = 2
}

variable "staging_worker_node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "staging_master_instance_type" {
  description = "Master node instance type"
  type        = string
  default     = "t3.large"
}

variable "staging_worker_instance_type" {
  description = "Worker node instance type"
  type        = string
  default     = "t3.xlarge"
}

# Staging Database Variables
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

variable "staging_db_allocated_storage" {
  description = "Allocated storage for staging DB"
  type        = number
  default     = 50
}

variable "staging_db_instance_class" {
  description = "Staging DB instance class"
  type        = string
  default     = "db.t3.small"
}

variable "staging_backup_retention_period" {
  description = "Staging backup retention period"
  type        = number
  default     = 7
}

variable "staging_multi_az" {
  description = "Staging Multi-AZ enabled"
  type        = bool
  default     = true
}

# Staging Cache Variables
variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "7.0"
}

variable "staging_redis_node_type" {
  description = "Staging Redis node type"
  type        = string
  default     = "cache.t3.small"
}

variable "staging_redis_num_cache_nodes" {
  description = "Staging Redis number of cache nodes"
  type        = number
  default     = 3
}

variable "staging_redis_automatic_failover" {
  description = "Staging Redis automatic failover"
  type        = bool
  default     = true
}

# ALB Variables
variable "certificate_arn" {
  description = "SSL certificate ARN"
  type        = string
}
