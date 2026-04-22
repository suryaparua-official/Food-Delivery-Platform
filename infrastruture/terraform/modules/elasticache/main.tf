terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name_prefix    = "${var.project_name}-redis-subnet-"
  subnet_ids     = var.private_subnet_ids

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-redis-subnet-${var.environment}"
    }
  )
}

# Redis Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id_prefix      = "${var.project_name}-redis-"
  engine                 = "redis"
  engine_version         = var.redis_version
  node_type              = var.node_type
  num_cache_nodes        = var.num_cache_nodes
  port                   = var.redis_port
  
  parameter_group_name   = aws_elasticache_parameter_group.main.name
  subnet_group_name      = aws_elasticache_subnet_group.main.name
  security_group_ids     = [var.elasticache_security_group_id]
  
  automatic_failover_enabled = var.automatic_failover_enabled
  maintenance_window         = "sun:03:00-sun:04:00"
  notification_topic_arn     = var.sns_topic_arn
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.auth_token
  
  log_delivery_configuration {
    destination      = var.log_group_name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    enabled          = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-redis-${var.environment}"
    }
  )

  depends_on = [aws_elasticache_subnet_group.main, aws_elasticache_parameter_group.main]
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "main" {
  name_prefix = "${var.project_name}-redis-params-"
  family      = "redis${var.redis_version}"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-redis-params-${var.environment}"
    }
  )
}
