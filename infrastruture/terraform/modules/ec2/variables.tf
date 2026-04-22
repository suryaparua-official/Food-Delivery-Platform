variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "master_security_group_id" {
  description = "Master security group ID"
  type        = string
}

variable "worker_security_group_id" {
  description = "Worker security group ID"
  type        = string
}

variable "master_node_count" {
  description = "Number of master nodes"
  type        = number
  default     = 3
}

variable "worker_node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "master_instance_type" {
  description = "EC2 instance type for master nodes"
  type        = string
  default     = "t3.large"
}

variable "worker_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.xlarge"
}

variable "master_root_volume_size" {
  description = "Master node root volume size in GB"
  type        = number
  default     = 50
}

variable "master_data_volume_size" {
  description = "Master node data volume size in GB"
  type        = number
  default     = 100
}

variable "worker_root_volume_size" {
  description = "Worker node root volume size in GB"
  type        = number
  default     = 50
}

variable "worker_data_volume_size" {
  description = "Worker node data volume size in GB"
  type        = number
  default     = 150
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "enable_bastion" {
  description = "Enable bastion host"
  type        = bool
  default     = false
}

variable "bastion_allowed_cidrs" {
  description = "CIDR blocks allowed to access bastion"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}
